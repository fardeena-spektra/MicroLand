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

        $bucketName = "lab-bucket-$deployment_id"

        $bucket = Get-S3Bucket | Where-Object {
            $_.BucketName -eq $bucketName
        }

        if (-not $bucket) {
            throw "Bucket '$bucketName' not found."
        }

        $versioning = Get-S3BucketVersioning -BucketName $bucketName

        if ($versioning.Status -ne "Enabled") {

            $message = @{
                Status  = "Failed"
                Message = "TASK-2 validation failed. Versioning is not enabled on bucket '$bucketName'."
            } | ConvertTo-Json

        }
        else {

            $objects = Get-S3Object -BucketName $bucketName

            if (-not $objects) {

                $message = @{
                    Status  = "Failed"
                    Message = "TASK-2 validation failed. No objects found in bucket '$bucketName'."
                } | ConvertTo-Json

            }
            else {

                $message = @{
                    Status  = "Succeeded"
                    Message = "TASK-2 validation passed."
                } | ConvertTo-Json
            }
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

