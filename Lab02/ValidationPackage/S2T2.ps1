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

        $stackName = "Lab-VPC-Stack-$deployment_id"
        $expectedVpcName = "Lab-VPC-$deployment_id"
        $expectedCidr = "10.0.0.0/16"

        #
        # Verify Stack Exists
        #
        $stack = Get-CFNStack `
            -StackName $stackName `
            -Region $region `
            -ErrorAction Stop |
            Select-Object -First 1

        if (-not $stack) {
            throw "Stack '$stackName' was not found."
        }

        #
        # Verify Stack Status
        #
        if ($stack.StackStatus -ne "CREATE_COMPLETE") {
            throw "Stack status is '$($stack.StackStatus)'. Expected CREATE_COMPLETE."
        }

        #
        # Get Stack Resources
        #
        $resources = Get-CFNStackResourceList `
            -StackName $stackName `
            -Region $region `
            -ErrorAction Stop

        $vpcResource = $resources |
            Where-Object {
                $_.ResourceType -eq "AWS::EC2::VPC"
            } |
            Select-Object -First 1

        if (-not $vpcResource) {
            throw "No VPC resource found in stack '$stackName'."
        }

        #
        # Verify VPC Exists
        #
        $vpcId = $vpcResource.PhysicalResourceId

        if (-not $vpcId) {
            throw "Unable to determine VPC ID."
        }

        $vpc = Get-EC2Vpc `
            -VpcId $vpcId `
            -Region $region `
            -ErrorAction Stop

        if (-not $vpc) {
            throw "VPC '$vpcId' was not found."
        }

        #
        # Verify CIDR Block
        #
        if ($vpc.CidrBlock -ne $expectedCidr) {
            throw "VPC CIDR '$($vpc.CidrBlock)' does not match '$expectedCidr'."
        }

        #
        # Verify Name Tag
        #
        $nameTag = (
            $vpc.Tags |
            Where-Object {
                $_.Key -eq "Name"
            }
        ).Value

        if ($nameTag -ne $expectedVpcName) {
            throw "VPC Name tag '$nameTag' does not match '$expectedVpcName'."
        }

        #
        # Success
        #
        $message = @{
            Status  = "Succeeded"
            Message = "TASK-2 validation passed."
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