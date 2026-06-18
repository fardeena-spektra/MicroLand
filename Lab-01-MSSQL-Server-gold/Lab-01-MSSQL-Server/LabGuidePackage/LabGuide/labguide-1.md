# Exercise 1: Diagnose and Tune a Slow Query

### Estimated Duration: 60 Minutes

## Lab Overview

A business-critical reporting query against the **`SalesDB`** database filters orders by customer: it reads from **`dbo.Orders`** (~100,000 rows) with a predicate on **`CustomerId`**. After data growth it has become **slow**. You are the Database Administrator. **Query Store** is enabled on `SalesDB` to help you locate the regressed query.

This is an **assessment**: each task gives you the **symptom and the required outcome** — not the steps. Diagnose the root cause yourself, then fix it. After the task, press **Validate** to score it.

> **Note:** Connect to the **primary** SQL node over SSH and use `sqlcmd` with the **SA** login (password in `/home/labuser/README.txt`).

## Task 1: Tune the slow query on SalesDB.Orders

**Symptom:** A query of the form `SELECT ... FROM dbo.Orders WHERE CustomerId = <value>` runs slowly. Its execution plan shows a **full scan** of the clustered index because there is no index supporting the `CustomerId` predicate.

**Required outcome:** The query that filters `dbo.Orders` on `CustomerId` no longer performs a full table/clustered-index scan — instead it uses an **index seek**. Concretely, a suitable **nonclustered index exists on `dbo.Orders(CustomerId)`** so the predicate can be satisfied by a seek.

Use Query Store (or the DMVs such as `sys.dm_exec_query_stats`) and the actual execution plan to confirm the scan and the cost, then apply an indexing or query-tuning change so the engine resolves the `CustomerId` filter with an index seek. Do not drop or truncate the `Orders` table; keep all ~100,000 rows in place.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="5b8a7a39-c3a3-4b63-b993-b80671f6f5de" />
