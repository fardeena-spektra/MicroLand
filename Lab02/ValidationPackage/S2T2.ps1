$region = "us-east-1"
$deployment_id = $deployment_id

Set-DefaultAWSRegion -Region $region

$stopRetry = $false
[int]$retryCount = 0
$maxRetries = 3

do {
    try {

        # Authentication Check
        $identity = Get-STSCallerIdentity -ErrorAction Stop
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
            throw "Stack '$stackName' not found."
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
        $resources = Get-CFNStackResource `
            -StackName $stackName `
            -Region $region `
            -ErrorAction Stop

        if ($resources.StackResourceSummaries) {
            $resources = $resources.StackResourceSummaries
        }

        $vpcResource = $resources |
            Where-Object {
                $_.ResourceType -eq "AWS::EC2::VPC"
            } |
            Select-Object -First 1

        if (-not $vpcResource) {
            throw "No VPC resource found in stack '$stackName'."
        }

        #
        # Verify Actual VPC Exists
        #
        $vpcId = $vpcResource.PhysicalResourceId

        if (-not $vpcId) {
            throw "Unable to determine VPC ID from stack resources."
        }

        $vpcResponse = Get-EC2Vpc `
            -VpcId $vpcId `
            -Region $region `
            -ErrorAction Stop

        if ($vpcResponse.Vpcs) {
            $vpc = $vpcResponse.Vpcs | Select-Object -First 1
        }
        else {
            $vpc = $vpcResponse
        }

        if (-not $vpc) {
            throw "VPC '$vpcId' not found."
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
        $nameTag = $vpc.Tags |
            Where-Object { $_.Key -eq "Name" } |
            Select-Object -ExpandProperty Value -First 1

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
                Message = $_.Exception.Message
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





# $region = "us-east-1"
# $deployment_id = $deployment_id

# Set-DefaultAWSRegion -Region $region

# $stopRetry = $false
# [int]$retryCount = 0
# $maxRetries = 3

# do {
#     try {

#         # Authentication Check
#         $identity = Get-STSCallerIdentity
#         $identity.Arn | Out-Null

#         $stackName = "Lab-VPC-Stack-$deployment_id"
#         $expectedVpcName = "Lab-VPC-$deployment_id"
#         $expectedCidr = "10.0.0.0/16"

#         #
#         # Verify Stack Exists
#         #
#         $stack = Get-CFNStack `
#             -StackName $stackName `
#             -Region $region `
#             -ErrorAction Stop

#         if (-not $stack) {
#             throw "Stack '$stackName' not found."
#         }

#         #
#         # Verify Stack Status
#         #
#         if ($stack.StackStatus -ne "CREATE_COMPLETE") {
#             throw "Stack status is '$($stack.StackStatus)'. Expected CREATE_COMPLETE."
#         }

#         #
#         # Get Stack Resources
#         #
#         $resources = Get-CFNStackResource `
#             -StackName $stackName `
#             -Region $region

#         $vpcResource = $resources |
#             Where-Object {
#                 $_.ResourceType -eq "AWS::EC2::VPC"
#             } |
#             Select-Object -First 1

#         if (-not $vpcResource) {
#             throw "No VPC resource found in stack."
#         }

#         #
#         # Verify Actual VPC Exists
#         #
#         $vpcId = $vpcResource.PhysicalResourceId

#         $vpc = Get-EC2Vpc `
#             -VpcId $vpcId `
#             -Region $region

#         if (-not $vpc) {
#             throw "VPC '$vpcId' not found."
#         }

#         #
#         # Verify CIDR Block
#         #
#         if ($vpc.CidrBlock -ne $expectedCidr) {
#             throw "VPC CIDR '$($vpc.CidrBlock)' does not match '$expectedCidr'."
#         }

#         #
#         # Verify Name Tag
#         #
#         $nameTag = $vpc.Tags |
#             Where-Object { $_.Key -eq "Name" } |
#             Select-Object -ExpandProperty Value

#         if ($nameTag -ne $expectedVpcName) {
#             throw "VPC Name tag '$nameTag' does not match '$expectedVpcName'."
#         }

#         #
#         # Success
#         #
#         $message = @{
#             Status  = "Succeeded"
#             Message = "TASK-2 validation passed."
#         } | ConvertTo-Json

#         Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
#             StatusCode = [System.Net.HttpStatusCode]::OK
#             Body       = $message
#         })

#         $stopRetry = $true
#     }
#     catch {

#         if ($retryCount -ge $maxRetries) {

#             $message = @{
#                 Status  = "Failed"
#                 Message = "Retry exhausted: $($_.Exception.Message)"
#             } | ConvertTo-Json

#             Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
#                 StatusCode = [System.Net.HttpStatusCode]::OK
#                 Body       = $message
#             })

#             $stopRetry = $true
#         }
#         else {

#             Start-Sleep -Seconds 60
#             $retryCount++
#         }
#     }

# } while ($stopRetry -eq $false)