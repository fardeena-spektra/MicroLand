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

        $instanceName = "labvm-$deployment_id"
        $roleName = "Lab-S3-ReadOnly-Role"
        $policyName = "AmazonS3ReadOnlyAccess"

        #
        # Verify EC2 Instance Exists
        #
        $instance = (
            Get-EC2Instance -Region $region -Filter @{
                Name   = "tag:Name"
                Values = $instanceName
            }
        ).Instances | Select-Object -First 1

        if (-not $instance) {
            throw "EC2 instance '$instanceName' was not found."
        }

        #
        # Verify IAM Instance Profile Attached
        #
        if (-not $instance.IamInstanceProfile) {
            throw "No IAM Instance Profile attached to '$instanceName'."
        }

        #
        # Get Instance Profile Name
        #
        $profileName = ($instance.IamInstanceProfile.Arn -split "/")[-1]

        #
        # Verify Role Exists in Instance Profile
        #
        $profile = Get-IAMInstanceProfile `
            -InstanceProfileName $profileName

        $roleExists = $profile.Roles |
            Where-Object {
                $_.RoleName -eq $roleName
            }

        if (-not $roleExists) {
            throw "Role '$roleName' is not attached to instance '$instanceName'."
        }

        #
        # Verify Policy Attached to Role
        #
        $policyExists = Get-IAMAttachedRolePolicies `
            -RoleName $roleName |
            Where-Object {
                $_.PolicyName -eq $policyName
            }

        if (-not $policyExists) {
            throw "Policy '$policyName' is not attached to role '$roleName'."
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