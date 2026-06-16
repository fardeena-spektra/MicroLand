# **Exercise 4: Host a Static Website Using Amazon S3**

## **Lab Overview**

In this lab, you will use Amazon S3 to host a static website and make it accessible through the S3 website endpoint. Static website hosting is a common AWS capability used to publish HTML, CSS, JavaScript, and other web assets without managing traditional web servers.

You will create an S3 bucket configured for website hosting, upload website content, enable public access to the required objects, and verify that the website is accessible from a browser.

Static website hosting is widely used for landing pages, documentation sites, portfolios, and lightweight web applications.

---

## **Scenario**

You have recently joined the Cloud Operations team as an AWS Administrator.

Your organization needs a simple informational website to publish company announcements without provisioning and maintaining EC2 instances.

Your manager has asked you to configure an Amazon S3 bucket to host a static website and verify that users can access the published content using the generated website endpoint.

You have been provided access to the AWS Management Console and must complete the deployment.

---

## **Solution**

To address this requirement, you will create an S3 bucket dedicated to website hosting, upload the required website files, configure static website hosting settings, and allow public read access to the content.

You will then validate that the website is accessible using the generated S3 website URL.

The solution demonstrates core AWS concepts including S3 configuration, bucket policies, object permissions, and static website hosting.

---

## **Learning Objectives**

After completing this lab, you will be able to:

* Create an Amazon S3 bucket.
* Configure static website hosting.
* Upload website content to S3.
* Configure bucket permissions for public access.
* Access a website using the S3 website endpoint.

---

## **Environment Information**

You will use the AWS Management Console.

Services used:

* Amazon S3

Website files required:

* `index.html`
* Optional supporting assets (CSS, images, JavaScript)

---

## **Assessment Objectives**

### **Task 1: Configure an S3 Bucket for Website Hosting**

Create an S3 bucket and enable static website hosting.

The bucket must:

* Use a globally unique name.
* Enable static website hosting.
* Configure `index.html` as the index document.

---

### **Task 2: Publish and Verify Website Content**

Upload website content and configure permissions.

The solution must:

* Upload the website files.
* Allow public access to website content.
* Verify that the website loads successfully.

---

## **Task 1: Configure an S3 Bucket for Website Hosting**

### **Task Overview**

In this task, you will create an S3 bucket and enable static website hosting.

---

**Step 1: Open Amazon S3**

From the AWS Console:

Navigate to:

`Services → S3`

---

**Step 2: Create the Bucket**

Select:

`Create bucket`

Configure:

| Setting          | Value                        |
| ---------------- | ---------------------------- |
| Bucket Name      | static-website-<unique-name> |
| AWS Region       | Default Region               |
| Object Ownership | ACLs Disabled                |

Select:

`Create bucket`

---

**Step 3: Disable Block Public Access**

Open the bucket.

Navigate to:

`Permissions`

Under:

`Block public access`

Select:

`Edit`

Disable:

`Block all public access`

Acknowledge the warning.

Save changes.

---

**Step 4: Enable Static Website Hosting**

Navigate to:

`Properties`

Under:

`Static website hosting`

Select:

`Edit`

Configure:

| Setting                | Value                 |
| ---------------------- | --------------------- |
| Static Website Hosting | Enable                |
| Hosting Type           | Host a static website |
| Index Document         | index.html            |

Save changes.

---

### **Task 1 Success Criteria**

Your configuration is successful when:

* The S3 bucket exists.
* Static website hosting is enabled.
* The index document is configured.
* Public access settings allow website hosting.

---

After completing the task, click the **Validation** tab.

<validation step="0c612a60-e805-4973-b619-320b491b3428" />

---

## **Task 2: Publish and Verify Website Content**

### **Task Overview**

In this task, you will upload website files and verify accessibility.

---

**Step 1: Create Website Content**

Create a file named:

`index.html`

Sample content:

```html
<html>
<head>
<title>CloudLabs Website</title>
</head>
<body>
<h1>Welcome to CloudLabs</h1>
<p>Static Website Hosting Lab</p>
</body>
</html>
```

Save the file.

---

**Step 2: Upload Website Files**

Inside the bucket:

Select:

`Upload`

Upload:

`index.html`

Complete the upload.

---

**Step 3: Configure Bucket Policy**

Navigate to:

`Permissions`

Under:

`Bucket Policy`

Select:

`Edit`

Update:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicRead",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::<bucket_name>/index.html"
        }
    ]
}
```

Save changes.

---

**Step 4: Retrieve Website Endpoint**

Navigate to:

`Properties`

Locate:

`Static website hosting`

Copy the:

`Bucket website endpoint`

Example:

```text
http://static-website-demo.s3-website-us-east-1.amazonaws.com
```

---

**Step 5: Verify Website Accessibility**

Open the website endpoint in a browser.

Expected output:

`text
Welcome to CloudLabs
Static Website Hosting Lab
`

---

## **Task 2 Success Criteria**

Your solution is successful when:

* Website files are uploaded.
* Public read access is configured.
* The website endpoint is accessible.
* The webpage displays successfully.

---

After completing the task, click the **Validation** tab.

<validation step="449a550b-831b-4b93-8c83-4059c7523819" />

---

## **Evaluation Criteria**

Your submission will be evaluated based on:

* Correct S3 bucket creation.
* Proper static website configuration.
* Successful upload of website files.
* Correct public access configuration.
* Successful website accessibility verification.
* Completion of all validation checks.

---

## **Completion Criteria**

You have successfully completed the assessment when:

* An S3 bucket is configured for static website hosting.
* Website content has been uploaded.
* Public access permissions are configured correctly.
* The website endpoint displays the expected content.
* All validation checks complete successfully.

You have successfully completed the Assessment.
