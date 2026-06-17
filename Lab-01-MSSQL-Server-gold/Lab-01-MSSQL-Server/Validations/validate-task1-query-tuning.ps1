Import-Module Az.Compute
Import-Module Az.Accounts

# Validation step: 1c50afe8-464e-4264-b904-d79f325ddc1b
# Exercise 1 / Task 1 - Tune the slow query on SalesDB.Orders (index seek on CustomerId)

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
# Passes when a NONCLUSTERED index on dbo.Orders(CustomerId) exists in SalesDB,
# so the slow "WHERE CustomerId = <n>" query can use an index seek.
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

idx_count=$("$SQLCMD" $SQLARGS -S localhost -U SA -P "$SA_PASSWORD" -d SalesDB -h -1 -W -Q \
"SET NOCOUNT ON; SELECT COUNT(*) FROM sys.indexes i JOIN sys.index_columns ic ON i.object_id=ic.object_id AND i.index_id=ic.index_id JOIN sys.columns c ON ic.object_id=c.object_id AND ic.column_id=c.column_id WHERE i.object_id=OBJECT_ID('dbo.Orders') AND c.name='CustomerId' AND i.type_desc='NONCLUSTERED';" 2>/dev/null)

idx_count=$(echo "$idx_count" | tr -dc '0-9')

if [ -n "$idx_count" ] && [ "$idx_count" -ge 1 ]; then
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
                Message = "A nonclustered index on dbo.Orders(CustomerId) exists in SalesDB on VM '$vmName', so the CustomerId query can use an index seek instead of a full scan."
            } | ConvertTo-Json
        }
        else {

            $message = @{
                Status  = "Failed"
                Message = "The slow query is not tuned on VM '$vmName'. Create a nonclustered index on dbo.Orders(CustomerId) in SalesDB (e.g. CREATE NONCLUSTERED INDEX IX_Orders_CustomerId ON dbo.Orders(CustomerId)) so the CustomerId predicate uses an index seek."
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
