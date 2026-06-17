This Package Includes

Deliverables Included in the Package

• Lab Guide
• Master Document
• Inline Validations
• ARM Deployment + Custom Script Extension
• Solution Guide (facilitator-only)
• Instructor Brief (facilitator-only)

Inline Validations

Pre-configured inline validations enabled (2 task validations, in-VM via CloudLabs VM Agent — PowerShell, executed against the primary SQL node with sqlcmd). Each task maps to a validation script keyed by a validation-step UUID; see Validations/Validation.md.

Inline Assessment Questions

Not included in this package (knowledge-check questions are out of scope for this assessment).

Lab Environment Setup & Deployment

Lab provisioning and setup include one or more of the following components:

• ARM template deployment — TWO CloudLabs Linux JumpVMs (Ubuntu Server 22.04 LTS, Standard_D2s_v3), each running SQL Server 2022 for Linux: the primary (labvm-<DeploymentID>, 10.0.0.4) and the secondary AG node (sqlnode2, 10.0.0.5), on a shared VNet/subnet
• Custom Script Extension (CSE / Bash) — installs mssql-server + mssql-tools on both nodes, enables the Always On hadr feature, and on the primary seeds SalesDB (dbo.Orders ~100k rows with an UNINDEXED CustomerId column + Query Store enabled)
• NSG allows SSH (22) from anywhere and SQL (1433) + AG endpoint (5022) within the VNet
• Supporting deployment configurations as required

Assessment Profile

• Domain: MS SQL Server / Azure SQL / Sybase
• Level: Intermediate
• Target duration: 120 minutes (120 minutes provisioned)
• Hosting tier: A (native — Azure Linux VMs running SQL Server on Linux, two nodes, Standard_D2s_v3)

Scenario & Validation Summary

• Exercise 1 / Task 1 — Tune the slow query on SalesDB.Orders (index seek on CustomerId) → validate-task1-query-tuning.ps1
• Exercise 2 / Task 1 — Configure Always On Availability Group AG_Sales (synchronous-commit, synchronized) → validate-task2-always-on.ps1

IMPORTANT NOTE — Always On automatic failover requires a cluster manager

SQL Server Always On Availability Groups with AUTOMATIC failover require a cluster manager — Pacemaker on Linux, or WSFC on Windows — together with a fencing agent. Configuring that cluster layer is intricate and is NOT reliably provisioned by a single Custom Script Extension; it may require additional platform orchestration beyond the CSE. The deployment therefore builds the achievable end-state: SQL Server installed on both nodes, the hadr feature enabled, a sample database on the primary, and the AG endpoint/certificate prerequisites documented for the candidate. Candidates can create the AG, configure synchronous-commit replication, reach a SYNCHRONIZED/HEALTHY state, and perform a MANUAL failover. The Exercise 2 validator checks this achievable end-state (AG_Sales exists and a database replica is SYNCHRONIZED) and does not require automatic failover.

Note: SQL Server package installation requires internet access at deploy time; the bootstrap guards every install step so the CSE never hard-fails.

Exclusions

This package does not include:

• Scoring or grading mechanisms beyond pass/fail inline validations
• Inline assessment questions
• Pacemaker/WSFC cluster manager configuration for automatic AG failover (out of scope; see note above)
