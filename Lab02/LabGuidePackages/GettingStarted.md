# AWS Cloud Challenge Lab 
**Duration: 90 Minutes**

## Overview

Welcome to the **AWS CloudFormation Challenge Lab**. In this lab, you will use a **Windows virtual machine** and the **AWS Management Console** to build and deploy CloudFormation YAML templates for common AWS infrastructure scenarios.

During the lab, you will create an Amazon S3 bucket with versioning enabled, deploy a VPC with subnets and route tables, create an IAM role for EC2 with Amazon S3 read access, and host a static website using Amazon S3. You will verify your work by using both the AWS console and validation checks provided in the lab.

## Accessing Your Lab Environment

This lab provides a **Windows VM** that you will use to review instructions and complete the required tasks. Use the credentials and connection details provided in the lab environment to access the virtual machine.

1. From the lab environment page, locate the connection details for the virtual machine.
2. Open the VM from the lab interface.
3. Wait for the desktop session to load completely before starting the exercises.
4. Keep the lab instructions available while you work through each task.

![](./media/gettingstarted-01.png)

## AWS Console & Lab Guide

Use the lab guide together with the AWS Management Console throughout this challenge. Read each exercise carefully before making changes in AWS so that your deployed resources match the required configuration.

As you progress through the lab, use the console to review stack deployments, inspect resources, and confirm that your templates produce the expected outcomes.

![](./media/gettingstarted-02.png)

## Exploring Your Lab Resources

Your lab environment is designed to support template authoring, deployment, and verification. During this challenge, you will work with resources and services that support the following tasks:

- Creating CloudFormation JSON templates
- Deploying stacks by using AWS CloudFormation
- Verifying Amazon S3 configuration and versioning
- Reviewing Amazon VPC networking resources
- Checking IAM role trust and permissions
- Validating Amazon S3 static website hosting

## Utilizing the Split Window Feature

For a better experience, use the split window feature so that you can view the **lab guide** and your **lab environment** at the same time. This helps you follow the instructions while completing the tasks without switching back and forth repeatedly.

![](./media/gettingstarted-03.png)

## Accessing the AWS Management Console

Use the following steps to sign in to the AWS Management Console:

1. Open the AWS sign-in page: <inject key="AwsConsoleUrl"></inject>
2. Sign in with the following credentials:
   - **IAM user name:** <inject key="IamUserName"></inject>
   - **IAM user password:** <inject key="IamUserPassword"></inject>
3. After sign-in, verify that you are working in AWS account **<inject key="AwsAccountId"></inject>**.
4. Keep your deployment identifier available if you need it during the lab: **<inject key="DeploymentID"></inject>**.

![](./media/gettingstarted-04.png)

## AWS Region

Make sure that you complete the entire lab in **AWS Region** **<inject key="AwsRegion"></inject>**.

> [!Important]
> If you switch to a different Region, your resources, CloudFormation stacks, and validation results may not match the lab requirements.

## Lab Guide Zoom In / Zoom Out

You can adjust the zoom level of the lab guide to improve readability while working through the instructions. Use the zoom controls available in the lab interface as needed.

## Lab Validation

This challenge includes validation checks to help confirm that each exercise has been completed correctly. Run validation only after finishing the required steps for an exercise.

If a validation does not pass, review your deployed resources, confirm the selected AWS Region, and correct the issue before trying again.

## Assessment Best Practices

- Read each instruction fully before you begin a task.
- Stay in the required AWS Region throughout the lab.
- Use the AWS Management Console to verify your deployed resources.
- Confirm that your CloudFormation templates match the exercise objectives.
- Save your work frequently as you progress through the exercises.

## Support Contact

If you encounter issues with the lab environment, contact your lab administrator or the support channel provided for your course.

## Learner Support

If you need help during the lab, review the current exercise instructions carefully, verify that you are signed in with the provided AWS credentials, and make sure you are still working in the correct AWS Region.

Click **Next >>** to continue.

## After publishing

> [!Note] These steps run **after** you push the template to CloudLabs — they verify CloudLabs can actually serve this lab guide to candidates.

- **Verify docs-proxy access:** open Templates → your template → **Lab Guide Settings** in <https://admin.cloudlabs.ai> and confirm CloudLabs can reach this repo via the docs proxy. If the repo is private, configure GitHub access at the template level.
- **Verify inline questions and inline validations:** sign in to <https://admin.cloudlabs.ai>, open your template, and walk through one full lab run to confirm every `<question>` and `<validation step="..."/>` renders correctly. Fix any that don't resolve.
