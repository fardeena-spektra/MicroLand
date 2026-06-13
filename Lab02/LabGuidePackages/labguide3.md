# **Exercise 3: Deploy an IAM role for EC2 with Amazon S3 read access**

## **Lab Overview**

In this lab, you will use AWS Identity and Access Management (IAM) to create an IAM role and attach an AWS managed policy to control permissions for AWS services and users.

IAM roles provide temporary permissions and are widely used in AWS environments to implement the principle of least privilege and secure access to AWS resources.

## **Scenario**

You have recently joined the Cloud Security team as a DevOps Engineer.

The organization requires controlled access to AWS resources through IAM roles instead of using long-term credentials. Your manager has asked you to create an IAM role and attach the required permissions using an AWS managed policy.

You have been provided access to an AWS environment and must configure the IAM role according to organizational requirements.

## **Solution**

To address this requirement, you will first create an IAM role with the appropriate trusted entity. You will then attach an AWS managed policy to grant the required permissions and verify that the role has been configured successfully.

This exercise demonstrates identity and access management concepts commonly used in AWS environments.

---

## **Learning Objectives**

After completing this lab, you will be able to:

* Create IAM roles.
* Configure trusted entities.
* Attach AWS managed policies.
* Verify IAM role configurations.
* Understand role-based access control in AWS.

---

## **Environment Information**

You have been provided access to:

* AWS Management Console
* IAM permissions to create and manage roles

AWS Region:

```text id="rgv8ma"
us-east-1
```

---

## **Assessment Objectives**

### **Task 1: Create an IAM Role**

Create an IAM role that:

* Uses AWS service as the trusted entity.
* Allows EC2 to assume the role.
* Is successfully created.

---

### **Task 2: Attach an IAM Policy**

Configure the IAM role to:

* Attach the AWS managed policy:

```text id="kfyj2a"
AmazonS3ReadOnlyAccess
```

* Verify that the policy is attached successfully.

---

# **Detailed Instructions**

# **Task 1: Create an IAM Role**

## **Task Overview**

In this task, you will create a new IAM role.

### **Step 1: Open IAM**

From the AWS Management Console, search for:

```text id="d3hjqp"
IAM
```

Select the IAM service.

---

### **Step 2: Navigate to Roles**

From the navigation pane, choose:

```text id="v5w29f"
Roles
```

Choose:

```text id="e8ucqj"
Create role
```

---

### **Step 3: Configure Trusted Entity**

Select:

```text id="g0zpsm"
AWS service
```

Use case:

```text id="ar4mvt"
EC2
```

Choose:

```text id="qp2lxy"
Next
```

---

### **Step 4: Specify Role Name**

Role Name:

```text id="lfn2de"
Lab-S3-ReadOnly-Role
```

Choose:

```text id="k9v8tn"
Create role
```

---

## **Task 1 Success Criteria**

Your solution is successful when:

* The IAM role exists.
* EC2 is configured as the trusted entity.
* The role has been created successfully.

---

After completing the task, click the **Validation** tab.

<validation step="7620ec9f-a258-42e0-9b06-4c2a5999d828" />

---

# **Task 2: Attach an IAM Policy**

## **Task Overview**

In this task, you will attach an AWS managed policy to the IAM role.

### **Step 1: Open the IAM Role**

Select the role created in Task 1:

```text id="yxk8zr"
Lab-S3-ReadOnly-Role
```

---

### **Step 2: Add Permissions**

Choose:

```text id="cm4lba"
Add permissions
```

Select:

```text id="jb3yfw"
Attach policies
```

---

### **Step 3: Select Policy**

Search for:

```text id="rtm2nh"
AmazonS3ReadOnlyAccess
```

Select the policy.

Choose:

```text id="h9v3gx"
Add permissions
```

---

### **Step 4: Verify Policy Attachment**

Confirm that the following policy appears under Permissions:

```text id="m4qfzk"
AmazonS3ReadOnlyAccess
```

---

## **Task 2 Success Criteria**

Your solution is successful when:

* The IAM role contains the required policy.
* The policy attachment completes successfully.
* Permissions are visible on the role.

---

After completing the task, click the **Validation** tab.

<validation step="6d00fcc7-8a30-4f7e-a2b6-2701b3e5db64" />

---

## **Evaluation Criteria**

Your submission will be evaluated based on:

### **Task 1**

* Correct creation of the IAM role.
* Proper trusted entity configuration.
* Successful validation completion.

### **Task 2**

* Correct policy attachment.
* Successful verification of permissions.
* Successful validation completion.

---

## **Completion Criteria**

You have successfully completed the assessment when:

* An IAM role named `Lab-S3-ReadOnly-Role` exists.
* EC2 is configured as the trusted entity.
* The `AmazonS3ReadOnlyAccess` policy is attached.
* Both validation steps complete successfully.

You have successfully completed the Assessment.
