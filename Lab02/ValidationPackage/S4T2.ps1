powershell
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

        $validationPassed = $false

        # Retrieve all S3 buckets
        $buckets = Get-S3Bucket

        if (-not $buckets) {
            throw "No S3 buckets found."
        }

        foreach ($bucket in $buckets) {

            try {

                # Verify website hosting is enabled
                $websiteConfig = Get-S3BucketWebsite `
                    -BucketName $bucket.BucketName `
                    -ErrorAction Stop

                if (-not $websiteConfig) {
                    continue
                }

                # Verify index.html exists
                $objects = Get-S3Object `
                    -BucketName $bucket.BucketName `
                    -KeyPrefix "index.html"

                if (-not $objects) {
                    continue
                }

                # Verify website endpoint accessibility
                $websiteUrl = "http://{0}.s3-website-{1}.amazonaws.com" -f `
                    $bucket.BucketName, $region

                try {

                    $response = Invoke-WebRequest `
                        -Uri $websiteUrl `
                        -UseBasicParsing `
                        -TimeoutSec 30

                    if ($response.StatusCode -eq 200) {
                        $validationPassed = $true
                        break
                    }

                }
                catch {
                    continue
                }

            }
            catch {
                continue
            }
        }

        if ($validationPassed) {

            $message = @{
                Status  = "Succeeded"
                Message = "TASK-2 validation passed."
            } | ConvertTo-Json
        }
        else {

            $message = @{
                Status  = "Failed"
                Message = "TASK-2 validation failed. Static website is not accessible or index.html was not found."
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