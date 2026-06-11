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

        # Get all buckets
        $buckets = Get-S3Bucket

        if (-not $buckets) {
            throw "No S3 buckets found."
        }

        $validationPassed = $false

        foreach ($bucket in $buckets) {

            try {

                $websiteConfig = Get-S3BucketWebsite `
                    -BucketName $bucket.BucketName `
                    -ErrorAction Stop

                if ($websiteConfig) {
                    $validationPassed = $true
                    break
                }

            }
            catch {
                continue
            }
        }

        if ($validationPassed) {

            $message = @{
                Status  = "Succeeded"
                Message = "TASK-1 validation passed."
            } | ConvertTo-Json
        }
        else {

            $message = @{
                Status  = "Failed"
                Message = "TASK-1 validation failed. No S3 bucket with static website hosting enabled was found."
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

