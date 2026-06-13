$region = "us-east-1"
$deployment_id = $deployment_id

Set-DefaultAWSRegion -Region $region

$stopRetry = $false
[int]$retryCount = 0
$maxRetries = 3

do {
    try {

        $identity = Get-STSCallerIdentity
        $identity.Arn | Out-Null

        $roleName = "Lab-S3-ReadOnly-Role"

        $role = Get-IAMRole -RoleName $roleName -ErrorAction Stop

        if (-not $role) {
            throw "Role '$roleName' was not found."
        }

        if ($role.Path -like "/aws-service-role/*") {

            $message = @{
                Status  = "Failed"
                Message = "TASK-1 validation failed. '$roleName' is an AWS service-linked role."
            } | ConvertTo-Json
        }
        else {

            $message = @{
                Status  = "Succeeded"
                Message = "TASK-1 validation passed."
            } | ConvertTo-Json
        }

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
                Message = "Retry exhausted: $($_.Exception.Message)"
            } | ConvertTo-Json

            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [System.Net.HttpStatusCode]::OK
                Body       = $message
            })

            $stopRetry = $true
        }
        else {

            Start-Sleep -Seconds 60
            $retryCount++
        }
    }

} while ($stopRetry -eq $false)