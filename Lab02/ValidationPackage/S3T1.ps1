$region = "us-east-1"
$deployment_id = $deployment_id

Set-DefaultAWSRegion -Region $region

$stopRetry = $false
[int]$retryCount = 0
$maxRetries = 3

do {
    try {

        # Authentication Check
        $identity = Get-STSCallerIdentity
        $identity.Arn | Out-Null

        # Verify that a custom IAM role exists
        $roles = Get-IAMRole

        if (-not $roles) {
            throw "No IAM roles found."
        }

        $customRoleFound = $false

        foreach ($role in $roles) {

            # Ignore AWS service-linked roles
            if ($role.Path -notlike "/aws-service-role/*") {

                $customRoleFound = $true
                break
            }
        }

        if ($customRoleFound) {

            $message = @{
                Status  = "Succeeded"
                Message = "TASK-1 validation passed."
            } | ConvertTo-Json
        }
        else {

            $message = @{
                Status  = "Failed"
                Message = "TASK-1 validation failed. No custom IAM role was found."
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

