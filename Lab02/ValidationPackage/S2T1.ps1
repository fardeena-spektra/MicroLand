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

        $bucketName = "cftbucket-$deployment_id"
        $templateKey = "vpc-template.yaml"
        $expectedVpcName = "Lab-VPC-$deployment_id"
        $expectedCidr = "10.0.0.0/16"

        #
        # Verify S3 bucket exists
        #
        $bucket = Get-S3Bucket |
            Where-Object { $_.BucketName -eq $bucketName }

        if (-not $bucket) {
            throw "Bucket '$bucketName' not found."
        }

        #
        # Verify template file exists
        #
        $object = Get-S3Object `
            -BucketName $bucketName `
            -Key $templateKey `
            -ErrorAction SilentlyContinue

        if (-not $object) {
            throw "Template '$templateKey' not found in bucket '$bucketName'."
        }

        #
        # Download template content
        #
        $tempFile = Join-Path $env:TEMP "vpc-template.yaml"

        Read-S3Object `
            -BucketName $bucketName `
            -Key $templateKey `
            -File $tempFile `
            -Region $region `
            -ErrorAction Stop

        $templateContent = Get-Content $tempFile -Raw

        #
        # Validate VPC resource
        #
        if ($templateContent -notmatch "AWS::EC2::VPC") {
            throw "Template does not define AWS::EC2::VPC."
        }

        #
        # Validate CIDR block
        #
        if ($templateContent -notmatch [regex]::Escape($expectedCidr)) {
            throw "Template does not contain CIDR '$expectedCidr'."
        }

        #
        # Validate Name tag
        #
        if ($templateContent -notmatch [regex]::Escape($expectedVpcName)) {
            throw "Template does not contain VPC Name '$expectedVpcName'."
        }

        #
        # Success
        #
        $message = @{
            Status  = "Succeeded"
            Message = "TASK-1 validation passed."
        } | ConvertTo-Json

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