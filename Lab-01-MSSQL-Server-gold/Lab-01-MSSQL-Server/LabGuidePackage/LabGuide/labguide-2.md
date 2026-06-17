# Exercise 2: Configure an Always On Availability Group

### Estimated Duration: 60 Minutes

## Lab Overview

The platform team needs **high availability** for the sales database. Two SQL Server 2022 on Linux nodes are provisioned — the **primary** (`labvm`, `10.0.0.4`) and the **secondary** (`sqlnode2`, `10.0.0.5`) — each with the Always On **`hadr`** feature already enabled. You must configure an **Always On Availability Group** across both nodes with **synchronous-commit** replication and bring the secondary into a synchronized state.

This is an **assessment**: the task gives you the **required outcome**, not the exact commands. Choose your own approach using `sqlcmd` and T-SQL. After the task, press **Validate** to score it.

> **Note:** Connect to the **primary** SQL node over SSH and use `sqlcmd` with the **SA** login. You will also need a session on **`sqlnode2`** to join the secondary replica. The endpoint port **TCP 5022** and SQL **1433** are open within the VNet.

> **Honest caveat — read before you start:** An Always On Availability Group with **automatic** failover requires a **cluster manager** (Pacemaker on Linux, or WSFC on Windows) plus a fencing agent. That layer is **intricate and is not pre-provisioned** by this lab and may require additional platform orchestration. You can still create the AG, configure synchronous-commit replication, reach a **SYNCHRONIZED/HEALTHY** state, and perform a **manual** failover — which is exactly what this task and its validator check.

## Task 1: Build the AG_Sales Availability Group with synchronous-commit replication

**Symptom:** There is no Availability Group; the sales database exists on only one node, with no replica protecting it against the loss of that node.

**Required outcome:**

- An **Always On Availability Group named `AG_Sales`** exists, with the **two SQL nodes as replicas** (primary on `10.0.0.4`, secondary on `10.0.0.5`).
- The replicas are configured for **synchronous-commit** replication.
- The secondary database is in a **SYNCHRONIZED / HEALTHY** state (i.e. `sys.dm_hadr_database_replica_states` reports `synchronization_state_desc = 'SYNCHRONIZED'`).

On both nodes, create the database-mirroring **endpoint** on **TCP 5022** with a master key and certificate so the endpoints trust each other. On the primary, **`CREATE AVAILABILITY GROUP AG_Sales`** with both replicas in `AVAILABILITY_MODE = SYNCHRONOUS_COMMIT`; on the secondary, **`JOIN`** the group and join the restored database. Confirm the secondary reaches a synchronized, healthy state.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="57bccd72-32bb-42ce-a3ba-dc58a10aceea" />
