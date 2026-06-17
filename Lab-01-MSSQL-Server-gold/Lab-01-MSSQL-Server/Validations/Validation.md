[CloudLabs Validator](https://spektra-systems.visualstudio.com/CloudLabs-Validator)

Lab Code: MSSQLSERVERLAB01

> Validations for this assessment run **in-VM** via the CloudLabs VM Agent (PowerShell HTTP-trigger
> functions) against the **primary** SQL node using `sqlcmd`. Each task maps to a script in this folder,
> keyed by its `<validation step="…"/>` UUID. Every validator retries up to 3 times
> (`Start-Sleep -Seconds 10`), always returns HTTP `OK`, and carries the pass/fail in the JSON `Status`
> field (`Succeeded`/`Failed`).

| Task | Validation step UUID | Script |
|---|---|---|
| Exercise 1 / Task 1 — Tune the slow query on SalesDB.Orders | 1c50afe8-464e-4264-b904-d79f325ddc1b | validate-task1-query-tuning.ps1 |
| Exercise 2 / Task 1 — Configure Always On Availability Group AG_Sales | 57bccd72-32bb-42ce-a3ba-dc58a10aceea | validate-task2-always-on.ps1 |
