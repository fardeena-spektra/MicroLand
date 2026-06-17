# CloudLabs by Spektra Systems | Facilitator Solution Guide (NOT for candidates)

## MS SQL Server — Query Tuning & Always On AG (Lab 01): Answer Key + Walkthrough

This document mirrors the candidate exercise order. Each task lists the recommended diagnosis, the fix commands (T-SQL via `sqlcmd`), the expected result, and the validation expectation. All work is performed over SSH on two Ubuntu nodes running SQL Server 2022 for Linux. The **SA** password is `NedSQL@1234!`; `sqlcmd` is at `/opt/mssql-tools/bin/sqlcmd` (or `/opt/mssql-tools18/bin/sqlcmd -C`).

---

## Exercise 1 / Task 1 — Tune the slow query on SalesDB.Orders

**Objective:** The `WHERE CustomerId = <n>` query on `SalesDB.dbo.Orders` uses an **index seek** instead of a full clustered-index scan, via a nonclustered index on `dbo.Orders(CustomerId)`.

**Diagnosis:**

```bash
SQLCMD=/opt/mssql-tools/bin/sqlcmd      # or: /opt/mssql-tools18/bin/sqlcmd -C
$SQLCMD -S localhost -U SA -P 'NedSQL@1234!' -d SalesDB -Q "
SET STATISTICS IO ON;
SELECT COUNT(*) FROM dbo.Orders WHERE CustomerId = 1234;   -- many logical reads = full scan
"
```

```sql
-- Find the regressed query in Query Store (top by avg duration)
SELECT TOP 5 qt.query_sql_text, rs.avg_duration, rs.avg_logical_io_reads
FROM sys.query_store_query_text qt
JOIN sys.query_store_query q ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
ORDER BY rs.avg_duration DESC;

-- Or via DMVs
SELECT TOP 5 qs.total_logical_reads, qs.execution_count,
       SUBSTRING(st.text, 1, 200) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '%Orders%CustomerId%'
ORDER BY qs.total_logical_reads DESC;
```

The plan for the `CustomerId` filter shows a **Clustered Index Scan** of `PK_Orders` because no index covers `CustomerId`.

**Fix:**

```sql
-- Create a nonclustered index so the predicate is satisfied by a seek.
CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
    ON dbo.Orders(CustomerId);

-- Optional covering variant (avoids key lookups for common columns):
-- CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
--     ON dbo.Orders(CustomerId) INCLUDE (OrderDate, Amount, Status);
```

```bash
$SQLCMD -S localhost -U SA -P 'NedSQL@1234!' -d SalesDB -Q "
SET STATISTICS IO ON;
SELECT COUNT(*) FROM dbo.Orders WHERE CustomerId = 1234;   -- now an Index Seek, few reads
"
```

**Expected result:** The query now produces an **Index Seek** on `IX_Orders_CustomerId` with far fewer logical reads; `sys.indexes` shows a nonclustered index whose key column is `CustomerId`.

**Validation:** `validate-task1-query-tuning.ps1` runs `sqlcmd` on the primary and counts nonclustered indexes on `dbo.Orders` whose key includes `CustomerId`; **≥ 1** → `Succeeded`.

---

## Exercise 2 / Task 1 — Configure Always On Availability Group AG_Sales

**Objective:** An Availability Group `AG_Sales` exists with both nodes as replicas in synchronous-commit, and the secondary database is `SYNCHRONIZED`.

> **Caveat:** Automatic failover requires a cluster manager (Pacemaker on Linux / WSFC on Windows) plus a fencing agent — intricate and **not** pre-provisioned. The steps below create the AG, configure synchronous-commit, reach SYNCHRONIZED, and perform a **manual** failover, which is what the validator checks.

**Step 1 — Endpoint prerequisites on BOTH nodes** (`10.0.0.4` primary, `10.0.0.5` secondary):

```sql
-- On EACH node:
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'NedSQL@1234!';
CREATE CERTIFICATE ag_cert WITH SUBJECT = 'AG_Sales cert';
BACKUP CERTIFICATE ag_cert
    TO FILE = '/var/opt/mssql/data/ag_cert.cer'
    WITH PRIVATE KEY (FILE = '/var/opt/mssql/data/ag_cert.pvk',
                      ENCRYPTION BY PASSWORD = 'NedSQL@1234!');

CREATE ENDPOINT hadr_endpoint
    STATE = STARTED
    AS TCP (LISTENER_PORT = 5022)
    FOR DATA_MIRRORING (ROLE = ALL,
                        AUTHENTICATION = CERTIFICATE ag_cert,
                        ENCRYPTION = REQUIRED ALGORITHM AES);
```

Copy each node's `ag_cert.cer` / `ag_cert.pvk` to the other node (e.g. `scp`), then on each node import the **partner's** certificate so the endpoints trust each other:

```sql
-- On EACH node, import the OTHER node's public certificate:
CREATE CERTIFICATE ag_cert_partner
    FROM FILE = '/var/opt/mssql/data/ag_cert_partner.cer';
```

**Step 2 — Create the AG on the PRIMARY (`10.0.0.4`):**

```sql
CREATE AVAILABILITY GROUP AG_Sales
    WITH (DB_FAILOVER = ON, CLUSTER_TYPE = EXTERNAL)
    FOR DATABASE SalesDB
    REPLICA ON
      'labvm'    WITH (ENDPOINT_URL = 'TCP://10.0.0.4:5022',
                       AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
                       FAILOVER_MODE = MANUAL,
                       SEEDING_MODE = AUTOMATIC),
      'sqlnode2' WITH (ENDPOINT_URL = 'TCP://10.0.0.5:5022',
                       AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
                       FAILOVER_MODE = MANUAL,
                       SEEDING_MODE = AUTOMATIC);
```

> `CLUSTER_TYPE = EXTERNAL` is used for AGs managed by Pacemaker; for a lab-only manual setup you may use `CLUSTER_TYPE = NONE` with `FAILOVER_MODE = MANUAL`. Either reaches a SYNCHRONIZED state for the validator.

**Step 3 — Join from the SECONDARY (`10.0.0.5`):**

```sql
ALTER AVAILABILITY GROUP AG_Sales JOIN WITH (CLUSTER_TYPE = EXTERNAL);
ALTER AVAILABILITY GROUP AG_Sales GRANT CREATE ANY DATABASE;   -- enables automatic seeding
```

If not using automatic seeding, instead back up `SalesDB` (full + log) from the primary, restore `WITH NORECOVERY` on the secondary, then `ALTER DATABASE SalesDB SET HADR AVAILABILITY GROUP = AG_Sales;` on the secondary.

**Step 4 — Confirm synchronized state (on the primary):**

```sql
SELECT ag.name, drs.synchronization_state_desc, drs.synchronization_health_desc
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_groups ag ON drs.group_id = ag.group_id
WHERE ag.name = 'AG_Sales';
-- Expect synchronization_state_desc = SYNCHRONIZED, synchronization_health_desc = HEALTHY
```

**Step 5 — Manual failover test (optional, demonstrates HA):**

```sql
-- Run on the SECONDARY to make it the new primary (sync-commit, no data loss):
ALTER AVAILABILITY GROUP AG_Sales FAILOVER;
```

**Expected result:** `sys.availability_groups` lists `AG_Sales`; `sys.dm_hadr_database_replica_states` shows the database `SYNCHRONIZED`/`HEALTHY`; a manual failover promotes `sqlnode2` without data loss.

**Validation:** `validate-task2-always-on.ps1` runs `sqlcmd` on the primary and passes when `AG_Sales` exists (`sys.availability_groups`, count ≥ 1) **and** at least one replica database is `SYNCHRONIZED` (`sys.dm_hadr_database_replica_states`, count ≥ 1).

---

### Facilitator Notes

- Both validators run in-VM via the CloudLabs VM Agent (PowerShell HTTP-trigger functions) against the **primary** node with `sqlcmd`; HTTP is always `OK` and pass/fail lives in the JSON `Status` field. They are read-only state checks and safe to re-run.
- **Automatic failover requires a cluster manager (Pacemaker on Linux / WSFC on Windows) and a fencing agent** — intricate and not provisioned by the CSE. The lab end-state (AG created, synchronous-commit, SYNCHRONIZED secondary, manual failover) is fully achievable and is what is graded.
- SQL Server install needs internet access at deploy time; if it was blocked, `sqlcmd` is absent and both validators report `Failed` until SQL Server is installed. The SA password is `NedSQL@1234!`.
- The Orders table is seeded with ~100,000 rows and an **unindexed** `CustomerId`; Query Store is `ON` and primed so the slow query appears in reports/DMVs.
