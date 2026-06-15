# **Exercise 2: Create CloudFormation Template for VPC**

## **Lab Overview**

In this lab, you will use AWS CloudFormation to automate the creation of networking infrastructure. You will create a CloudFormation template that provisions a Virtual Private Cloud (VPC), store the template in Amazon S3, and deploy the template to create the required resources.

Infrastructure as Code (IaC) enables organizations to standardize deployments, improve consistency, and reduce manual configuration errors.

---

## **Scenario**

You have recently joined the Cloud Engineering team as a DevOps Engineer.

The organization requires all network infrastructure to be provisioned using CloudFormation templates to ensure repeatable and auditable deployments.

Your manager has asked you to create a CloudFormation template that provisions a VPC, store the template in Amazon S3, and deploy the stack using AWS CloudFormation.

You have been provided access to an AWS environment to complete this task.

---

## **Solution**

To address this requirement, you will first create a CloudFormation template defining a VPC resource. You will upload the template to an S3 bucket and then deploy the template through AWS CloudFormation.

This exercise demonstrates Infrastructure as Code principles commonly used in AWS environments.

---

## **Learning Objectives**

After completing this lab, you will be able to:

* Create AWS CloudFormation templates.
* Define AWS resources using YAML.
* Store CloudFormation templates in Amazon S3.
* Deploy CloudFormation stacks.
* Verify deployed infrastructure.

---

## **Environment Information**

You have been provided access to:

* AWS Management Console
* Amazon S3 permissions
* AWS CloudFormation permissions

AWS Region:

```text
us-east-1
```

---

## **Assessment Objectives**

### **Task 1: Create and Upload a CloudFormation Template**

Create a template that defines:

* One Amazon VPC resource.
* A CIDR block of:

```text
10.0.0.0/16
```

* A Name tag of:

```text
Lab-VPC-<inject key="CloudLabsDeploymentID" enableCopy="true"/>
```

Upload the template to an S3 bucket named:

```text
cftbucket-<inject key="CloudLabsDeploymentID" enableCopy="true"/>
```

---

### **Task 2: Deploy the CloudFormation Stack**

Deploy the template and verify that:

* The stack completes successfully.
* The VPC resource is created.
* Stack status is successful.

---

# **Detailed Instructions**

# **Task 1: Create and Upload the CloudFormation Template**

## **Task Overview**

In this task, you will create a CloudFormation template and upload it to Amazon S3.

### **Step 1: Open VS Code**

Launch VS Code from the lab virtual machine.

---

### **Step 2: Create Template File**

Create a file named:

```text
vpc-template.yaml
```

---

### **Step 3: Define the VPC Resource**

Configure the template to create:

* Resource Type:

```text
AWS::EC2::VPC
```

* CIDR Block:

```yaml
10.0.0.0/16
```

* Name Tag:

```text
Lab-VPC-<inject key="CloudLabsDeploymentID" enableCopy="true"/>
```

---

### **Step 4: Save the Template**

Save the file:

```text
vpc-template.yaml
```

Verify the file exists.

---

### **Step 5: Create the S3 Bucket**

Using the AWS Console, create an S3 bucket named:

```text
cftbucket-<inject key="CloudLabsDeploymentID" enableCopy="true"/>
```

Ensure the bucket is created in:

```text
us-east-1
```

---

### **Step 6: Upload the Template**

Upload the following file into the bucket:

```text
vpc-template.yaml
```

Verify that the file appears inside the bucket.

---

## **Task 1 Success Criteria**

Your solution is successful when:

* The template file exists.
* The template defines a VPC resource.
* The correct CIDR block is configured.
* The correct VPC Name tag is configured.
* The template file is uploaded to the specified S3 bucket.

---

After completing the task, click the **Validation** tab.

<validation step="8dab43fd-28e8-4d72-8578-61ac9bd8f23a" />

---

# **Task 2: Deploy the CloudFormation Stack**

## **Task Overview**

In this task, you will deploy the CloudFormation stack.

### **Step 1: Open CloudFormation**

Search for:

```text
CloudFormation
```

Open the CloudFormation service.

---

### **Step 2: Create Stack**

Choose:

```text
Create stack
```

Select:

```text
With new resources (standard)
```

---

### **Step 3: Specify Template Source**

Choose:

```text
Amazon S3 URL
```

Use the template stored in Amazon S3 using the following URL format:

```text
https://cftbucket-<inject key="CloudLabsDeploymentID" enableCopy="true"/>.s3.amazonaws.com/vpc-template.yaml
```

Choose:

```text
Next
```


---

### **Step 4: Configure Stack**

Specify the stack name:

```text
Lab-VPC-Stack-<inject key="CloudLabsDeploymentID" enableCopy="true"/>
```

Choose:

```text
Next
```

Accept the default settings and continue.

---

### **Step 5: Select IAM role & Deploy Stack**
Select following role :

```
cft-vpc-role
```
Choose:

```text
Submit
```

Wait for deployment to complete.

---

### **Step 6: Verify Stack Status**

Confirm the stack status displays:

```text
CREATE_COMPLETE
```

Verify that the VPC resource exists.

---

## **Task 2 Success Criteria**

Your solution is successful when:

* The CloudFormation stack exists.
* Stack status is CREATE_COMPLETE.
* The VPC resource has been provisioned successfully.
* The deployed VPC has the expected Name tag.

---

After completing the task, click the **Validation** tab.

<validation step="a47918f9-093d-4e4f-9a30-fd62634b47e2" />

---

## **Evaluation Criteria**

Your submission will be evaluated based on:

### **Task 1**

* Correct creation of the CloudFormation template.
* Proper VPC configuration.
* Successful upload to Amazon S3.
* Successful validation completion.

### **Task 2**

* Successful stack deployment.
* Correct provisioning of the VPC.
* Correct stack naming.
* Successful validation completion.

---

## **Completion Criteria**

You have successfully completed the assessment when:

* A CloudFormation template defining a VPC exists.
* The template has been uploaded to the required S3 bucket.
* The CloudFormation stack has been deployed.
* The VPC resource has been created successfully.
* Both validation steps complete successfully.

You have successfully completed the Assessment.
