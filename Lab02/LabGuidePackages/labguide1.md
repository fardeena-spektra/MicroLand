# **Scenario 1: Create S3 Bucket with Versioning**

## Lab Overview

In this lab, you will use Amazon S3 to create and manage an object storage bucket and enable versioning to protect data from accidental deletion and overwrites.

Amazon S3 versioning is commonly used by organizations to maintain historical versions of objects, support recovery processes, and improve data protection strategies.

## Scenario

You have recently joined the Cloud Operations team as a Junior DevOps Engineer.

The organization stores application assets and deployment artifacts in Amazon S3. To improve data protection and maintain object history, your manager has asked you to create a new S3 bucket and enable versioning on the bucket.

You have been provided access to an AWS environment and must configure the bucket according to organizational requirements.

## Solution

To address this requirement, you will first create an Amazon S3 bucket using the AWS Management Console. After verifying the bucket creation, you will enable versioning to ensure multiple versions of uploaded objects can be retained.

This solution demonstrates fundamental AWS storage administration tasks frequently performed by DevOps engineers and cloud administrators.

---

## Learning Objectives

After completing this lab, you will be able to:

* Create Amazon S3 buckets.
* Configure bucket settings.
* Enable bucket versioning.
* Verify S3 bucket configurations.
* Understand object protection using versioning.

---

## Environment Information

You have been provided access to:

* AWS Management Console
* Appropriate permissions to manage Amazon S3 resources

AWS Region:

```text
us-east-1
```

---

## Assessment Objectives

### Task 1: Create an S3 Bucket

Create an Amazon S3 bucket that:

* Uses a globally unique bucket name.
* Is deployed in the provided AWS Region.
* Is successfully created.

---

### Task 2: Enable Bucket Versioning

Configure the S3 bucket to:

* Enable versioning.
* Retain multiple versions of uploaded objects.
* Verify that versioning is enabled.

---

# Detailed Instructions

# Task 1: Create an S3 Bucket

## Task Overview

In this task, you will create a new Amazon S3 bucket.

### Step 1: Open Amazon S3

From the AWS Management Console:

1. Search for:

```text
S3
```

2. Select **Amazon S3**.

---

### Step 2: Create the Bucket

Choose:

```text
Create bucket
```

---

### Step 3: Configure Bucket Details

Specify:

Bucket Name:

```text
lab-bucket-<inject key="CloudLabsDeploymentID"/>
```

AWS Region:

```text
us-east-1
```

Leave other settings as default.

---

### Step 4: Create the Bucket

Select:

```text
Create bucket
```

Verify that the bucket appears in the bucket list.

---

## Task 1 Success Criteria

Your solution is successful when:

* The S3 bucket exists.
* The bucket name matches the required format.
* The bucket is created in the correct AWS Region.

---

After completing the task, click the **Validation** tab.

<validation step="3d16c635-8911-455e-a4d9-623081184166" />

---

# Task 2: Enable Bucket Versioning

## Task Overview

In this task, you will enable versioning on the S3 bucket.

### Step 1: Open Bucket Properties

Select the bucket created in Task 1.

Choose:

```text
Properties
```

---

### Step 2: Edit Versioning Settings

Locate:

```text
Bucket Versioning
```

Choose:

```text
Edit
```

---

### Step 3: Enable Versioning

Select:

```text
Enable
```

Choose:

```text
Save changes
```

---

### Step 4: Verify Configuration

Confirm the status displays:

```text
Enabled
```

---

## Task 2 Success Criteria

Your solution is successful when:

* Bucket versioning is enabled.
* The bucket retains version history.
* The configuration has been saved successfully.

---

After completing the task, click the **Validation** tab.

<validation step="b48f9b97-91e1-4a1d-8ff8-fea87e4e3bf3" />

---

## Evaluation Criteria

Your submission will be evaluated based on:

### Task 1

* Correct creation of the S3 bucket.
* Proper bucket naming.
* Successful validation completion.

### Task 2

* Correct versioning configuration.
* Successful verification of versioning status.
* Successful validation completion.

---

## Completion Criteria

You have successfully completed the assessment when:

* An S3 bucket has been created.
* Bucket versioning has been enabled.
* Both validation steps complete successfully.

You have successfully completed the Assessment.
