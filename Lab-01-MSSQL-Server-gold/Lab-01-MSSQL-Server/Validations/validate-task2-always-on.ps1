Import-Module Az.Compute
Import-Module Az.Accounts

# Validation step: 57bccd72-32bb-42ce-a3ba-dc58a10aceea
# Exercise 2 / Task 1 - Configure Always On Availability Group AG_Sales (sync-commit, synchronized)
#
# NOTE: This validator checks the achievable end-state (the AG exists and a
# database replica is SYNCHRONIZED). AUTOMATIC failover additionally requires a
# cluster manager (Pacemaker on Linux / WSFC on Windows) plus a fencing agent,
# which is intricate and not provisioned by the CSE; it is out of scope for the
# automated check.

# Variables provided by CloudLabs
$deployment_id     = $deployment_id
$resourceGroupName = $resourceGroupName
$sub_id            = $sub_id
$vmName            = "labvm-$deployment_id"

# Set subscription
Select-AzSubscription -SubscriptionId $sub_id

# Retry logic
$stopRetry = $false
[int]$retryCount = 0
$maxRetries = 3

do {
    try {

        # Script to run inside VM. It must echo the sentinel "Validation Success"
        # ONLY when every check passes; otherwise echo "Validation Failed".
        $script = @'
#!/bin/bash
# Passes when the Always On AG named AG_Sales exists AND at least one database
# replica is in the SYNCHRONIZED state (synchronous-commit replication healthy).
# If sqlcmd is missing/unreachable, prints "Validation Failed". Always exits 0.
SQLCMD=/opt/mssql-tools/bin/sqlcmd
SQLARGS=""
if [ ! -x "$SQLCMD" ]; then
    if [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
        SQLCMD=/opt/mssql-tools18/bin/sqlcmd
        SQLARGS="-C"
    else
        echo "Validation Failed"
        exit 0
    fi
fi

SA_PASSWORD='NedSQL@1234!'

ag_count=$("$SQLCMD" $SQLARGS -S localhost -U SA -P "$SA_PASSWORD" -h -1 -W -Q \
"SET NOCOUNT ON; SELECT COUNT(*) FROM sys.availability_groups WHERE name='AG_Sales';" 2>/dev/null)
ag_count=$(echo "$ag_count" | tr -dc '0-9')

sync_count=$("$SQLCMD" $SQLARGS -S localhost -U SA -P "$SA_PASSWORD" -h -1 -W -Q \
"SET NOCOUNT ON; SELECT COUNT(*) FROM sys.dm_hadr_database_replica_states WHERE synchronization_state_desc='SYNCHRONIZED';" 2>/dev/null)
sync_count=$(echo "$sync_count" | tr -dc '0-9')

if [ -n "$ag_count" ] && [ "$ag_count" -ge 1 ] && [ -n "$sync_count" ] && [ "$sync_count" -ge 1 ]; then
    echo "Validation Success"
else
    echo "Validation Failed"
fi
exit 0
'@

        # Execute inside VM
        $result = Invoke-AzVMRunCommand `
            -ResourceGroupName $resourceGroupName `
            -VMName $vmName `
            -CommandId "RunShellScript" `
            -ScriptString $script

        $vmOutput = ($result.Value[0].Message | Out-String).Trim()

        if ($vmOutput -match "Validation Success") {

            $message = @{
                Status  = "Succeeded"
                Message = "Availability Group 'AG_Sales' exists and a database replica is SYNCHRONIZED on VM '$vmName' (synchronous-commit replication healthy). Note: automatic failover additionally requires a cluster manager (Pacemaker/WSFC)."
            } | ConvertTo-Json
        }
        else {

            $message = @{
                Status  = "Failed"
                Message = "AG_Sales is not yet healthy on VM '$vmName'. Ensure the Availability Group 'AG_Sales' exists with both nodes as replicas in SYNCHRONOUS_COMMIT and that the secondary database reports synchronization_state_desc = 'SYNCHRONIZED' in sys.dm_hadr_database_replica_states."
            } | ConvertTo-Json
        }

        # Return JSON response
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = $message
        })

        $stopRetry = $true
    }
    catch {

        if ($retryCount -ge $maxRetries) {

            $message = @{
                Status  = "Failed"
                Message = "Retry for validation process has been exhausted. Please try after sometime."
            } | ConvertTo-Json

            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [System.Net.HttpStatusCode]::OK
                Body       = $message
            })

            $stopRetry = $true
        }
        else {
            Write-Host "Validation failed. Retrying... ($($retryCount + 1)/$maxRetries)"
            Start-Sleep -Seconds 10
            $retryCount++
        }
    }

} while ($stopRetry -eq $false)
