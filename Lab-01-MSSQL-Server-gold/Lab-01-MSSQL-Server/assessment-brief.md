# Instructor Brief — MS SQL Server (Lab 01)

**Domain / Level:** MS SQL Server / Azure SQL / Sybase · Intermediate · **Hosting tier A** (native CloudLabs Linux JumpVMs running SQL Server 2022 on Linux, Ubuntu Server 22.04 LTS).
**Target time:** ~90 min work · **120 min** provisioned.
**Cloud field:** `azure` · **Level field:** `Intermediate`.

## Scenario

The candidate is the DBA for a sales platform on SQL Server. A reporting query against `SalesDB.dbo.Orders` filtering on `CustomerId` has become slow (full scan, no supporting index), and the platform needs high availability via an Always On Availability Group across two SQL nodes. The candidate must tune the query so it uses an index seek, then build the `AG_Sales` Availability Group with synchronous-commit replication and a synchronized secondary.

## Environment (seeded by `DeploymentPackage/bootstrap-01.sh`)

- **Two SQL Server 2022 on Linux nodes** (`Standard_D2s_v3`): primary `labvm-<DeploymentID>` (`10.0.0.4`, hostname `labvm`) and secondary `sqlnode2` (`10.0.0.5`). The bootstrap installs `mssql-server` + `mssql-tools`, sets the **SA** password to `NedSQL@1234!`, accepts the EULA (Developer edition), and enables the Always On **`hadr`** feature on **both** nodes.
- On the **primary**, database **`SalesDB`** holds **`dbo.Orders`** (~100,000 rows, clustered PK on `OrderId`). The **`CustomerId`** column is deliberately **not indexed**, so `WHERE CustomerId = <n>` performs a clustered-index scan. **Query Store is ON** (`READ_WRITE`, `QUERY_CAPTURE_MODE = ALL`) and primed with the slow query.
- The secondary node has SQL Server installed and `hadr` enabled, ready to join the AG.

## Answer key

- **Ex1 (query tuning):** Confirm the scan via Query Store / DMVs (`sys.query_store_runtime_stats`, `sys.dm_exec_query_stats`) and the actual plan, then create a supporting index:

  ```sql
  CREATE NONCLUSTERED INDEX IX_Orders_CustomerId ON dbo.Orders(CustomerId);
  ```

  Re-running `SELECT ... FROM dbo.Orders WHERE CustomerId = <n>` now shows an **index seek**. (Optionally add an `INCLUDE` for covering columns; the validator only requires a nonclustered index whose key includes `CustomerId`.)

- **Ex2 (Always On AG):** On **both** nodes, create the endpoint prerequisites and a mirroring endpoint on TCP 5022, then create/join `AG_Sales` in synchronous-commit:

  ```sql
  -- BOTH nodes: master key + certificate + mirroring endpoint (TCP 5022)
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'NedSQL@1234!';
  CREATE CERTIFICATE ag_cert WITH SUBJECT = 'AG_Sales cert';
  -- back up ag_cert, copy to the other node, CREATE CERTIFICATE ... FROM FILE, restore trust
  CREATE ENDPOINT hadr_endpoint
      STATE = STARTED
      AS TCP (LISTENER_PORT = 5022)
      FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = CERTIFICATE ag_cert, ENCRYPTION = REQUIRED ALGORITHM AES);

  -- PRIMARY (10.0.0.4): create the AG with both replicas SYNCHRONOUS_COMMIT
  CREATE AVAILABILITY GROUP AG_Sales
      FOR DATABASE SalesDB
      REPLICA ON
        'labvm'    WITH (ENDPOINT_URL = 'TCP://10.0.0.4:5022', AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, FAILOVER_MODE = MANUAL, SEEDING_MODE = AUTOMATIC),
        'sqlnode2' WITH (ENDPOINT_URL = 'TCP://10.0.0.5:5022', AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, FAILOVER_MODE = MANUAL, SEEDING_MODE = AUTOMATIC);

  -- SECONDARY (10.0.0.5): join the group and the database
  ALTER AVAILABILITY GROUP AG_Sales JOIN;
  ALTER AVAILABILITY GROUP AG_Sales GRANT CREATE ANY DATABASE;  -- for automatic seeding
  ```

  Confirm `sys.dm_hadr_database_replica_states.synchronization_state_desc = 'SYNCHRONIZED'`. (If not using automatic seeding, back up `SalesDB` full + log from the primary, restore `WITH NORECOVERY` on the secondary, then `ALTER DATABASE SalesDB SET HADR AVAILABILITY GROUP = AG_Sales` on the secondary.)

(Full commands and the manual-failover test are in `LabGuidePackage/Solution-Guide/solution-guide.md`.)

## Scoring rubric (100 pts)

| Item | Pts | Pass criteria (validator) |
|---|---|---|
| Ex1 — slow query tuned (nonclustered index on `dbo.Orders(CustomerId)`) | 50 | validate-task1-query-tuning.ps1 → Succeeded |
| Ex2 — `AG_Sales` AG exists, sync-commit, secondary SYNCHRONIZED | 50 | validate-task2-always-on.ps1 → Succeeded |

Pass ≥ 50 (at least one task fully complete). Intermediate sign-off = 100 with **both** tasks passing.

## Notes / caveats

- **Automatic failover requires a cluster manager.** A fully automatic Always On AG failover needs **Pacemaker** (Linux) or **WSFC** (Windows) plus a fencing agent. That cluster layer is intricate, is **not** provisioned by the CSE, and may require additional platform orchestration. The achievable end-state — AG created, synchronous-commit configured, secondary SYNCHRONIZED, **manual** failover working — is what the validator checks. Do not fail a candidate for the absence of automatic failover.
- Validators run in-VM via the CloudLabs VM Agent (PowerShell HTTP-trigger functions) against the **primary** node with `sqlcmd`; HTTP is always `OK` and pass/fail lives in the JSON `Status` field. They are read-only state checks and safe to re-run.
- `sqlcmd` may be at `/opt/mssql-tools/bin/sqlcmd` or `/opt/mssql-tools18/bin/sqlcmd` (the validators try both; the v18 path adds `-C` to trust the self-signed cert). SA password is `NedSQL@1234!`.
- SQL Server package install needs **internet access at deploy time**. The bootstrap guards every install step so the CSE never hard-fails; if install was blocked, `sqlcmd` will be absent and both validators report `Failed` until SQL Server is present.
- The working user is `labuser` (ARM `trainerUserName` / `adminUsername`); `README.txt` with credentials and topology is written to `/home/labuser`.
