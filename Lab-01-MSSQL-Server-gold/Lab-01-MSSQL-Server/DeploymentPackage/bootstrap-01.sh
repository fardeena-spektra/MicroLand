#!/usr/bin/env bash
# =============================================================================
# Lab 01 - MS SQL Server (Query Tuning & Always On Availability Group)
# bootstrap-01.sh  -  CloudLabs Custom Script Extension bootstrap
#
# Runs on BOTH SQL Server on Linux nodes:
#   * PRIMARY   = labvm-<DeploymentID> (hostname "labvm")  -> hosts Scenario 1's
#                 SalesDB and is the intended AG PRIMARY replica.
#   * SECONDARY = sqlnode2 (hostname "sqlnode2", 10.0.0.5) -> intended AG
#                 SECONDARY replica.
#
# On every node this script:
#   - installs SQL Server 2022 for Ubuntu (mssql-server) + mssql-tools (sqlcmd),
#   - sets the SA password and accepts the EULA,
#   - enables the Always On / hadr feature (mssql-conf set hadr.hadrenabled 1).
# On the PRIMARY only it additionally:
#   - creates database SalesDB,
#   - creates table dbo.Orders with ~100k rows and a CustomerId column WITHOUT
#     an index (so a query filtering on CustomerId performs a full scan = slow),
#   - turns on Query Store on SalesDB.
#
# Scenario 1 (s1): Diagnose the slow query on SalesDB.Orders (filter on
#                  CustomerId) with Query Store / DMVs and the execution plan,
#                  then add a nonclustered index so the query uses an index seek.
# Scenario 2 (s2): Configure an Always On Availability Group (AG_Sales) across
#                  the two nodes with synchronous-commit replication and test
#                  failover.
#
# IMPORTANT / HONEST CAVEAT:
#   SQL Server Always On AGs with AUTOMATIC failover require a cluster manager
#   (WSFC on Windows, or Pacemaker on Linux). That is intricate and is NOT
#   reliably provisioned by a single Custom Script Extension. This script builds
#   the achievable end-state (mssql-server + mssql-tools on both nodes, hadr
#   enabled, a sample database, and the AG endpoint/certificate prerequisites
#   documented in README.txt). Completing automatic failover additionally
#   requires Pacemaker and may need extra platform orchestration. The validators
#   check the achievable end-state via sqlcmd.
#
# NOTE: SQL Server package install needs INTERNET ACCESS at deploy time. Every
#       install step is guarded (try/continue) and must NOT hard-fail the CSE.
#
# Usage: bash bootstrap-01.sh <labuser>   (default: labuser)
# =============================================================================
set -uo pipefail

LAB_USER="${1:-labuser}"
LAB_HOME="/home/${LAB_USER}"

# Sample credentials / topology (documented for candidates in README.txt).
SA_PASSWORD="NedSQL@1234!"
PRIMARY_IP="10.0.0.4"          # CloudLabs primary NIC (dynamic, typically .4)
SECONDARY_IP="10.0.0.5"        # sqlnode2 static private IP
AG_NAME="AG_Sales"
DB_NAME="SalesDB"

# sqlcmd lives in one of these locations depending on the tools package.
SQLCMD_CLASSIC="/opt/mssql-tools/bin/sqlcmd"
SQLCMD_18="/opt/mssql-tools18/bin/sqlcmd"

log() { echo "[bootstrap] $*"; }

# Resolve which node we are on from the hostname (labvm = primary).
NODE_ROLE="secondary"
HOSTNAME_NOW="$(hostname 2>/dev/null || echo unknown)"
case "${HOSTNAME_NOW}" in
    labvm*) NODE_ROLE="primary" ;;
    *)      NODE_ROLE="secondary" ;;
esac

log "Starting Lab 01 MSSQL bootstrap for user '${LAB_USER}' on host '${HOSTNAME_NOW}' (role=${NODE_ROLE})"

# Ensure the lab user/home exists (CloudLabs normally provisions it; be safe).
if ! id "${LAB_USER}" >/dev/null 2>&1; then
    log "User ${LAB_USER} missing - creating it"
    useradd -m -s /bin/bash "${LAB_USER}" || true
fi
mkdir -p "${LAB_HOME}"

export DEBIAN_FRONTEND=noninteractive

# -----------------------------------------------------------------------------
# Base packages (best-effort)
# -----------------------------------------------------------------------------
log "Ensuring base packages (curl, gnupg, apt-transport-https) are present"
apt-get update -y >/dev/null 2>&1 || log "apt-get update failed (continuing)"
apt-get install -y curl gnupg apt-transport-https software-properties-common >/dev/null 2>&1 || \
    log "base package install reported issues (continuing)"

# -----------------------------------------------------------------------------
# Install SQL Server 2022 for Ubuntu (mssql-server) - guarded, never hard-fail
# -----------------------------------------------------------------------------
install_sql_server() {
    log "[SQL] Adding Microsoft package signing key and SQL Server 2022 repo (Ubuntu 22.04)"
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null \
        | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg 2>/dev/null \
        || { log "[SQL] WARNING: could not fetch signing key (needs internet) - skipping SQL install"; return 0; }

    curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list 2>/dev/null \
        -o /etc/apt/sources.list.d/mssql-server-2022.list \
        || { log "[SQL] WARNING: could not fetch mssql-server repo list - skipping SQL install"; return 0; }

    apt-get update -y >/dev/null 2>&1 || log "[SQL] apt-get update (mssql repo) failed (continuing)"
    apt-get install -y mssql-server >/dev/null 2>&1 \
        || { log "[SQL] WARNING: mssql-server install failed (needs internet) - continuing"; return 0; }

    # Unattended setup: Developer edition (free), accept EULA, set SA password.
    log "[SQL] Running mssql-conf setup (Developer edition, EULA accepted)"
    MSSQL_SA_PASSWORD="${SA_PASSWORD}" \
    MSSQL_PID="Developer" \
    ACCEPT_EULA="Y" \
        /opt/mssql/bin/mssql-conf -n setup >/dev/null 2>&1 \
        || log "[SQL] WARNING: mssql-conf setup reported issues (continuing)"

    # Enable the Always On / hadr feature on every node (required for AGs).
    log "[SQL] Enabling Always On hadr feature (mssql-conf set hadr.hadrenabled 1)"
    /opt/mssql/bin/mssql-conf set hadr.hadrenabled 1 >/dev/null 2>&1 \
        || log "[SQL] WARNING: could not enable hadr (continuing)"

    systemctl enable mssql-server >/dev/null 2>&1 || true
    systemctl restart mssql-server >/dev/null 2>&1 \
        || log "[SQL] WARNING: could not (re)start mssql-server (continuing)"
}

install_sql_tools() {
    log "[SQL] Installing mssql-tools (sqlcmd) + unixodbc-dev"
    curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list 2>/dev/null \
        -o /etc/apt/sources.list.d/msprod.list \
        || { log "[SQL] WARNING: could not fetch prod repo list for tools - skipping tools install"; return 0; }
    apt-get update -y >/dev/null 2>&1 || true
    ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev >/dev/null 2>&1 \
        || ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev >/dev/null 2>&1 \
        || { log "[SQL] WARNING: mssql-tools install failed (needs internet) - continuing"; return 0; }
}

install_sql_server
install_sql_tools

# Pick whichever sqlcmd got installed (classic first, then v18 with -C for trust).
SQLCMD=""
SQLCMD_ARGS=""
if [ -x "${SQLCMD_CLASSIC}" ]; then
    SQLCMD="${SQLCMD_CLASSIC}"
elif [ -x "${SQLCMD_18}" ]; then
    SQLCMD="${SQLCMD_18}"
    SQLCMD_ARGS="-C"   # trust self-signed server cert
fi

# Helper: run a T-SQL batch on the local instance (best-effort, retries while
# the engine finishes starting). Never hard-fails the CSE.
run_tsql() {
    local db="$1"; shift
    local sql="$1"; shift
    [ -z "${SQLCMD}" ] && { log "[SQL] sqlcmd not available - skipping T-SQL batch"; return 0; }
    local attempt=1
    while [ "${attempt}" -le 10 ]; do
        if "${SQLCMD}" ${SQLCMD_ARGS} -S localhost -U SA -P "${SA_PASSWORD}" -d "${db}" -b -Q "${sql}" >/dev/null 2>&1; then
            return 0
        fi
        log "[SQL] T-SQL attempt ${attempt}/10 not ready yet (engine starting?) - retrying"
        sleep 6
        attempt=$((attempt + 1))
    done
    log "[SQL] WARNING: T-SQL batch did not complete (engine may be offline) - continuing"
    return 0
}

# =============================================================================
# PRIMARY-ONLY SEED: SalesDB + Orders (no index) + Query Store
# =============================================================================
if [ "${NODE_ROLE}" = "primary" ]; then
    log "[Scenario 1] PRIMARY node - seeding ${DB_NAME} with an unindexed Orders table"

    # Create the database.
    run_tsql "master" "IF DB_ID('${DB_NAME}') IS NULL CREATE DATABASE [${DB_NAME}];"

    # Create dbo.Orders WITHOUT an index on CustomerId, then load ~100k rows.
    # A clustered PK exists on OrderId only; CustomerId is deliberately NOT
    # indexed so 'WHERE CustomerId = <n>' must scan the whole table = slow.
    run_tsql "${DB_NAME}" "
SET NOCOUNT ON;
IF OBJECT_ID('dbo.Orders','U') IS NOT NULL DROP TABLE dbo.Orders;
CREATE TABLE dbo.Orders (
    OrderId     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY CLUSTERED,
    CustomerId  INT          NOT NULL,
    OrderDate   DATETIME2(0) NOT NULL,
    Amount      DECIMAL(10,2) NOT NULL,
    Status      VARCHAR(20)  NOT NULL,
    Notes       VARCHAR(200) NULL
);
-- Load ~100,000 rows using a tally built from system catalog cross joins.
WITH n AS (
    SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Orders (CustomerId, OrderDate, Amount, Status, Notes)
SELECT
    (rn % 5000) + 1                                   AS CustomerId,
    DATEADD(MINUTE, -rn, SYSUTCDATETIME())            AS OrderDate,
    CAST(((rn % 1000) + 1) AS DECIMAL(10,2))          AS Amount,
    CASE rn % 3 WHEN 0 THEN 'OPEN' WHEN 1 THEN 'SHIPPED' ELSE 'CLOSED' END AS Status,
    CONCAT('seed order ', rn)                         AS Notes
FROM n;"

    # Turn on Query Store so the candidate can find the slow query.
    run_tsql "master" "ALTER DATABASE [${DB_NAME}] SET QUERY_STORE = ON;"
    run_tsql "master" "ALTER DATABASE [${DB_NAME}] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);"

    # Prime Query Store with the slow scan so it shows up in reports/DMVs.
    run_tsql "${DB_NAME}" "SET NOCOUNT ON; DECLARE @s INT; SELECT @s = COUNT(*) FROM dbo.Orders WHERE CustomerId = 1234;"

    log "[Scenario 1] ${DB_NAME}.dbo.Orders seeded (~100k rows, CustomerId UNINDEXED), Query Store ON"
else
    log "[Scenario 2] SECONDARY node (sqlnode2) - SQL Server installed, hadr enabled, ready to join ${AG_NAME}"
fi

# =============================================================================
# README for the candidate (written on both nodes; tasks reference it)
# =============================================================================
cat > "${LAB_HOME}/README.txt" <<EOF
Lab 01 - MS SQL Server (Query Tuning & Always On Availability Group)
===================================================================

Two SQL Server 2022 on Linux (Ubuntu 22.04) nodes are provisioned:

  Node 1 (PRIMARY)   : labvm-<DeploymentID>   private IP ${PRIMARY_IP} (hostname labvm)
                       -> hosts the ${DB_NAME} database for Scenario 1
                       -> intended Always On PRIMARY replica for Scenario 2
  Node 2 (SECONDARY) : sqlnode2               private IP ${SECONDARY_IP}
                       -> intended Always On SECONDARY replica for Scenario 2

SQL Server credentials (both nodes):
  Server   : localhost  (or the node's private IP from another node)
  Login    : SA
  Password : ${SA_PASSWORD}
  sqlcmd   : ${SQLCMD_CLASSIC}   (or ${SQLCMD_18} with -C to trust the cert)

Connect example:
  ${SQLCMD_CLASSIC} -S localhost -U SA -P '${SA_PASSWORD}'
  ${SQLCMD_18} -C -S localhost -U SA -P '${SA_PASSWORD}'

-------------------------------------------------------------------
Scenario 1 - Diagnose and tune a slow query
-------------------------------------------------------------------
  Database : ${DB_NAME}   Table : dbo.Orders (~100,000 rows)
  The query 'SELECT ... FROM dbo.Orders WHERE CustomerId = <n>' is SLOW because
  CustomerId has NO index, so the engine performs a full clustered-index scan.
  Query Store is ENABLED on ${DB_NAME} to help you find the regressed query.

  Goal: use Query Store / DMVs and the execution plan to confirm the scan, then
        tune the query so it uses an INDEX SEEK on CustomerId. A suitable
        nonclustered index on dbo.Orders(CustomerId) is the expected fix, e.g.:
          CREATE NONCLUSTERED INDEX IX_Orders_CustomerId ON dbo.Orders(CustomerId);

-------------------------------------------------------------------
Scenario 2 - Configure an Always On Availability Group (${AG_NAME})
-------------------------------------------------------------------
  Both nodes have SQL Server installed and the hadr feature ENABLED
  (mssql-conf set hadr.hadrenabled 1). You must create an Always On
  Availability Group named ${AG_NAME} spanning both nodes, with the secondary
  in SYNCHRONOUS_COMMIT, and the secondary database in a SYNCHRONIZED/HEALTHY
  state.

  High-level steps (full T-SQL is in the facilitator Solution Guide):
    1. On BOTH nodes: create a master key, a certificate, and a database-mirroring
       ENDPOINT listening on TCP 5022 (exchange/restore the certificate between
       nodes so the endpoints trust each other).
    2. On the PRIMARY (${PRIMARY_IP}): CREATE AVAILABILITY GROUP ${AG_NAME} with
       both replicas set to AVAILABILITY_MODE = SYNCHRONOUS_COMMIT and
       endpoint_url 'TCP://${PRIMARY_IP}:5022' and 'TCP://${SECONDARY_IP}:5022'.
    3. On the SECONDARY (${SECONDARY_IP}): ALTER AVAILABILITY GROUP ${AG_NAME} JOIN,
       then restore the seeded database with NORECOVERY and join it to the AG.

  *** HONEST CAVEAT ***
  AUTOMATIC failover for an Always On AG requires a CLUSTER MANAGER
  (Pacemaker on Linux, or WSFC on Windows). Installing and configuring
  Pacemaker + a fencing agent is intricate and is NOT provisioned by this
  bootstrap; it may need additional platform orchestration. You can still
  create the AG, configure synchronous-commit replication, reach a
  SYNCHRONIZED/HEALTHY state, and perform a MANUAL failover. The validators
  check this achievable end-state via sqlcmd.

Support: cloudlabs-support@spektrasystems.com | https://cloudlabs.ai/labs-support
EOF

# Ownership: lab user owns everything under its home.
log "Setting ownership of ${LAB_HOME} to ${LAB_USER}"
chown -R "${LAB_USER}:${LAB_USER}" "${LAB_HOME}" 2>/dev/null || \
    chown -R "${LAB_USER}" "${LAB_HOME}" 2>/dev/null || \
    log "WARNING: chown of ${LAB_HOME} failed"

log "Bootstrap complete (role=${NODE_ROLE})."
if [ "${NODE_ROLE}" = "primary" ]; then
    log "  PRIMARY: ${DB_NAME}.dbo.Orders (~100k rows, CustomerId UNINDEXED), Query Store ON, hadr enabled."
else
    log "  SECONDARY: SQL Server installed, hadr enabled, ready to join ${AG_NAME}."
fi
exit 0
