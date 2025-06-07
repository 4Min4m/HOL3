Serverless DevSecOps CI/CD Pipeline on AWS with Node.js

(Optional: Replace this placeholder image with your initial pipeline diagram from the request or an overall architecture diagram.)

Table of Contents
Introduction

Features & Highlights

Architecture Overview

Application Overview

Challenges Faced & Solutions

Prerequisites

Deployment Guide

1. Clone the Repository

2. Configure AWS CLI

3. Create GitHub Connection for CodePipeline

4. Deploy Core Infrastructure (CloudFormation Stacks)

5. Commit and Push Application Code & CodeDeploy Scripts

6. Trigger and Monitor the Pipeline

Verification & Screenshots

Maintaining the Environment & Cost Management

Cleanup (Crucial for AWS Free Tier)

Future Enhancements

Author

Introduction
This project demonstrates a robust and automated DevSecOps Continuous Integration/Continuous Delivery (CI/CD) pipeline built entirely on AWS CloudFormation (Infrastructure as Code - IaC) and orchestrated by AWS CodePipeline. The pipeline automates the process of taking Node.js application code from a GitHub repository, performing simulated security scans, building the application, and deploying it to dedicated Staging and Production EC2 instances.

A key focus of this project was to implement a secure and efficient pipeline while adhering strictly to AWS Free Tier limits, making it an ideal showcase for practical cloud development without incurring significant costs.

Features & Highlights
Automated CI/CD: Fully automated pipeline from code commit to deployment using AWS CodePipeline.

Infrastructure as Code (IaC): All AWS resources are defined and managed using CloudFormation templates for repeatability, version control, and consistency.

DevSecOps Integration (Simulated): Incorporates simulated Static Application Security Testing (SAST) and Software Composition Analysis (SCA) steps using AWS CodeBuild, demonstrating security shifts left.

Multi-Environment Deployment: Automated deployment to separate Staging and Production EC2 environments.

Manual Approvals: Implements mandatory manual approval gates before deploying to Staging and Production, ensuring quality and control.

Node.js Application: Deploys a simple "Hello World" Node.js Express.js application running on Ubuntu EC2 instances.

GitHub Integration: Leverages GitHub for source code management and integrates seamlessly with AWS CodePipeline via CodeStar Connections.

AWS Free Tier Conscious: Designed to minimize costs by utilizing t2.micro EC2 instances, S3 for artifact storage, and careful management of billable services.

Robust Shell Scripting: CodeDeploy lifecycle hooks are managed via shell scripts to ensure application installation, startup, and permissions are correctly handled on EC2 instances.

Architecture Overview
The pipeline's architecture follows best practices for CI/CD and DevSecOps on AWS:

Source: GitHub repository.

Orchestration: AWS CodePipeline.

Build & Security Scan: AWS CodeBuild for building the Node.js application and simulating security checks (SAST/SCA).

Deployment: AWS CodeDeploy for in-place deployments to EC2 instances.

Compute: Amazon EC2 instances (Ubuntu Server t2.micro).

Networking: Amazon VPC, Subnets, Internet Gateway, and Security Groups.

Identity & Access Management: AWS IAM roles with least-privilege principles for service interactions.

Notifications: Amazon SNS for manual approval alerts (optional, if email subscribed).

Logs: AWS CloudWatch Logs for monitoring CodeBuild and CodeDeploy events.

(Optional: Insert your DevSecOps Pipeline on AWS image here if you have one.)

Application Overview
The demo application is a minimal Node.js Express.js server that listens on port 3000 and serves a dynamic "Hello World" message indicating its deployment environment (Staging or Production).

app.js: Main application logic.

package.json: Node.js project metadata and dependencies.

.gitignore: Specifies files/directories to ignore in Git.

scripts/: Contains CodeDeploy lifecycle hook scripts (appspec.yml references these).

Challenges Faced & Solutions
Building complex cloud infrastructure as code often presents intricate challenges. This project successfully navigated several key hurdles:

CloudFormation Dependency Resolution: Ensuring correct !Ref and !ImportValue usage across multiple interdependent CloudFormation stacks (VPC, IAM, EC2, CodeDeploy, CodePipeline) to correctly link resources and outputs. This required meticulous ordering and precise export/import naming.

IAM Permissions Granularity: Diagnosing and implementing the exact IAM permissions required for cross-service interactions (e.g., CodePipeline calling CodeBuild, CodePipeline using CodeStar Connections, CodeDeploy interacting with S3 and EC2 instances). Initial AccessDenied errors were systematically addressed by adding specific inline policies.

EC2 UserData Scripting & Node.js Installation: Overcoming persistent npm: command not found and glibc dependency conflicts during Node.js installation on EC2 instances. The solution involved migrating from Amazon Linux 2 to a more Node.js-friendly Ubuntu AMI and refining the UserData script to use direct NodeSource installation and PM2 globally.

CodeDeploy Agent User Context & Permissions: Resolving EACCES: permission denied errors during npm install within CodeDeploy hooks. This stemmed from CodeDeploy copying files as root, while scripts ran as ubuntu. The solution involved explicitly changing file ownership to ubuntu within the AfterInstall hook.

CodeDeploy appspec.yml Configuration: Fine-tuning the appspec.yml to correctly define deployment destinations, user context (runas: ubuntu), and the Ec2TagFilters for targeting instances.

CodePipeline Source/Artifact Configuration: Addressing specific validation errors related to OutputArtifactFormat and ensuring CodeBuild artifact types (CODEPIPELINE) were correctly set when integrating with CodePipeline.

These challenges reinforced the importance of detailed logging, systematic debugging, and understanding the nuances of AWS service integrations.

Prerequisites
Before deploying this pipeline, ensure you have:

AWS Account: An active AWS account. Familiarize yourself with the AWS Free Tier limits.

GitHub Account: A GitHub account and a repository where you'll host this project's code.

AWS CLI Configured: The AWS Command Line Interface (CLI) installed and configured with credentials (preferably an IAM user with AdministratorAccess for initial setup, or appropriate granular permissions for CloudFormation deployments).

aws configure

EC2 Key Pair: An existing EC2 Key Pair in your AWS region for SSH access to instances. You can create one via the EC2 console.
(Note: The .pem file for this key pair should be kept secure on your local machine and NOT committed to Git.)

Deployment Guide
Follow these steps meticulously to deploy the entire DevSecOps pipeline using CloudFormation. Wait for each CloudFormation stack to reach CREATE_COMPLETE status before proceeding to the next step.

1. Clone the Repository
Clone this GitHub repository to your local machine or open it directly in a GitHub Codespace.

git clone https://github.com/your-github-username/your-repo-name.git
cd your-repo-name

(Replace your-github-username and your-repo-name with your actual details).

2. Configure AWS CLI
Ensure your AWS CLI is configured with your AWS Access Key ID, Secret Access Key, and a default region (e.g., us-east-1).

aws configure

3. Create GitHub Connection for CodePipeline
AWS CodePipeline needs permission to access your GitHub repository.

Go to the AWS CodePipeline console.

In the left navigation pane, choose Settings > Connections.

Click Create connection.

For Provider type, choose GitHub.

For Connection name, enter a descriptive name (e.g., MyGitHubConnection).

Click Connect to GitHub and follow the prompts to authorize AWS Connector for GitHub, selecting the repository for this project.

After successful connection, copy the Connection ARN. It will look like arn:aws:codestar-connections:REGION:ACCOUNT_ID:connection/CONNECTION_ID. Keep this ARN handy.

4. Deploy Core Infrastructure (CloudFormation Stacks)
The infrastructure will be deployed in a specific order due to dependencies.

Important Placeholders:

your-key-pair-name: The name of your EC2 Key Pair.

your-github-username: Your GitHub username (e.g., 4Min4m).

your-repo-name: Your GitHub repository name (e.g., AWS-env).

your-connection-arn: The ARN copied from Step 3 (e.g., arn:aws:codeconnections:us-east-1:864981715490:connection/743c9fe4-1a25-46e1-b068-daf51b807075).

4.1. Deploy VPC and Public Subnet (vpc.yaml)

This creates your network infrastructure.

aws cloudformation deploy \
  --template-file vpc.yaml \
  --stack-name DevSecOpsVPCStack \
  --capabilities CAPABILITY_NAMED_IAM

Wait for CREATE_COMPLETE.

4.2. Deploy IAM Roles (iam_roles.yaml)

This creates all necessary IAM roles with precise permissions for CodePipeline, CodeBuild, CodeDeploy, and EC2 instances.

Before running, ensure your iam_roles.yaml file has your actual GitHub Connection ARN inserted directly into the Resource field of the codestar-connections:UseConnection policy statement under CodePipelineServiceRole.
(It should look like Resource: arn:aws:codeconnections:us-east-1:864981715490:connection/743c9fe4-1a25-46e1-b068-daf51b807075)

aws cloudformation deploy \
  --template-file iam_roles.yaml \
  --stack-name DevSecOpsIAMRoles \
  --capabilities CAPABILITY_NAMED_IAM

Wait for CREATE_COMPLETE.

4.3. Deploy EC2 Instances (ec2_instances.yaml)

This creates your Staging and Production EC2 instances, including the updated Security Group to allow traffic on port 3000.

Before running, ensure your ec2_instances.yaml has the correct Default AMI ID for Ubuntu 22.04 LTS (e.g., ami-0a7d80731ae1b2435) and your KeyPairName.

aws cloudformation deploy \
  --template-file ec2_instances.yaml \
  --stack-name DevSecOpsEC2Instances \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      KeyPairName=your-key-pair-name

Wait for CREATE_COMPLETE. This step will take the longest (10-15+ minutes) due to instance provisioning and Node.js installation.

4.4. Deploy CodeDeploy Application & Deployment Groups (codedeploy.yaml)

This sets up CodeDeploy to manage your application deployments.

aws cloudformation deploy \
  --template-file codedeploy.yaml \
  --stack-name DevSecOpsCodeDeploy \
  --capabilities CAPABILITY_NAMED_IAM

Wait for CREATE_COMPLETE.

5. Commit and Push Application Code & CodeDeploy Scripts
This is CRITICAL before deploying the pipeline. The CodePipeline will pull the latest version of your code and deployment scripts from GitHub on its very first run.

Ensure your app.js, package.json, .gitignore, and all files in the scripts/ directory (appspec.yml, before_install.sh, after_install.sh, stop_application.sh, start_application.sh, validate_service.sh) are up-to-date and correctly configured for the Ubuntu environment (referencing /home/ubuntu and ubuntu user where appropriate, and including the chown commands in after_install.sh).

git add .
git commit -m "Initial Node.js app and final CodeDeploy scripts for Ubuntu deployment"
git push origin main # Or your default branch name

6. Deploy CodePipeline (codepipeline.yaml)
This is the final step, creating the main orchestration.

Before running, ensure your codepipeline.yaml has the correct GitHubRepoName, GitHubOwner, GitHubBranch, and GitHubConnectionArn.

aws cloudformation deploy \
  --template-file codepipeline.yaml \
  --stack-name DevSecOpsNodeJsPipelineStack \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      GitHubRepoName=your-repo-name \
      GitHubOwner=your-github-username \
      GitHubBranch=main \
      GitHubConnectionArn=your-connection-arn

Wait for CREATE_COMPLETE. This will automatically trigger the first pipeline execution.

Verification & Screenshots
Once the DevSecOpsNodeJsPipelineStack is CREATE_COMPLETE, and you've manually approved the Staging deployment, you can verify the application and capture proof of its functionality and your pipeline's success.

1. Full Pipeline Execution Success
Capture a screenshot of your DevSecOpsNodeJsPipeline in the AWS CodePipeline console, showing all stages displaying green "Succeeded" statuses. This is the ultimate proof that your CI/CD pipeline works end-to-end.

(Add screenshot here: images/pipeline_success.png)

2. Staging Environment Application
Get the Public IPv4 address of your DevSecOps-Staging-Instance from the EC2 console. Open your browser to http://<Staging_EC2_Public_IP>:3000. You should see your Node.js application running, explicitly indicating the "staging" environment. Capture a screenshot of this page.

(Add screenshot here: images/staging_app.png)

3. Production Environment Application
Once you've approved the Production deployment in CodePipeline, get the Public IPv4 address of your DevSecOps-Production-Instance from the EC2 console. Open your browser to http://<Production_EC2_Public_IP>:3000. You should see your Node.js application running, explicitly indicating the "production" environment. Capture a screenshot of this page.

(Add screenshot here: images/production_app.png)

4. CodeBuild Security Scan Logs
Navigate to your CodePipeline, click on the Build-SecurityScan stage, then click "Details" to open the CodeBuild project. Go to the "Logs" tab. You'll see the output from your simulated SAST/SCA checks. Capture a screenshot of relevant log lines showing these checks.

(Add screenshot here: images/security_scan_logs.png)

5. CodeDeploy Successful Events
In the CodePipeline console, click on the DeployToStaging or DeployToProduction stage, then click "Details" to open the CodeDeploy deployment. Navigate to the "Events" tab. You'll see all the lifecycle events (ApplicationStop, BeforeInstall, AfterInstall, ApplicationStart, ValidateService) listed with "Succeeded" status. This confirms your shell scripts executed correctly. Capture a screenshot of these successful events.

(Add screenshot here: images/codedeploy_events.png)

Maintaining the Environment & Cost Management
This project is designed to be mindful of AWS Free Tier limits. If you choose to keep the deployed environment for practice and further learning:

EC2 Instances: The t2.micro instances consume 750 free hours per month. To avoid charges, stop your EC2 instances (DevSecOps-Staging-Instance and DevSecOps-Production-Instance) when not in use. You can restart them when you need to practice. Running them continuously can exceed Free Tier limits.

Billing Alerts: It is highly recommended to set up AWS Billing Alerts to notify you if your estimated charges approach your Free Tier limits.

Other Services: Services like VPC, IAM, SNS, CodePipeline (one per month), CodeBuild (100 minutes/month), CodeDeploy, S3 (5GB), and CloudWatch Logs (5GB) generally have generous Free Tier limits that should not be exceeded by typical practice usage.

Cleanup (Crucial for AWS Free Tier)
It is absolutely critical to clean up all resources when you are finished with the project to avoid unexpected AWS charges.

Terminate EC2 Instances First:

Go to the AWS EC2 Console -> Instances.

Select both DevSecOps-Staging-Instance and DevSecOps-Production-Instance.

Click "Instance state" > "Terminate instance". Wait until they show "terminated" status.

Delete CodePipeline Artifact S3 Bucket First:

Go to the AWS S3 Console.

Find the bucket named like codepipeline-artifacts-REGION-ACCOUNT_ID.

You MUST empty its contents first, then delete the bucket.

Delete CloudFormation Stacks (in reverse dependency order):

Go to the AWS CloudFormation Console -> Stacks.

Run these commands sequentially from your Codespace terminal, waiting for each stack to be DELETE_COMPLETE before starting the next:

aws cloudformation delete-stack --stack-name DevSecOpsNodeJsPipelineStack
aws cloudformation wait stack-delete-complete --stack-name DevSecOpsNodeJsPipelineStack

aws cloudformation delete-stack --stack-name DevSecOpsCodeDeploy
aws cloudformation wait stack-delete-complete --stack-name DevSecOpsCodeDeploy

aws cloudformation delete-stack --stack-name DevSecOpsEC2Instances
aws cloudformation wait stack-delete-complete --stack-name DevSecOpsEC2Instances

aws cloudformation delete-stack --stack-name DevSecOpsIAMRoles
aws cloudformation wait stack-delete-complete --stack-name DevSecOpsIAMRoles

aws cloudformation delete-stack --stack-name DevSecOpsVPCStack
aws cloudformation wait stack-delete-complete --stack-name DevSecOpsVPCStack

Delete CodeStar Connection:

Go to AWS CodePipeline Console -> Settings -> Connections.

Select your GitHub connection and click "Delete".

Delete Other Lingering Resources:

CloudWatch Log Groups: Check AWS CloudWatch Console -> Log groups. Delete any starting with /aws/codebuild/DevSecOps....

CodeBuild Projects: Check AWS CodeBuild Console -> Build projects. Delete any DevSecOps prefixed projects (if not cleaned by stack deletion).

SNS Topic: Check AWS SNS Console -> Topics. Delete DevSecOpsApprovalNotification.

Future Enhancements
Real Security Tools: Integrate actual SAST (e.g., Snyk CLI, SonarScanner) and DAST (e.g., OWASP ZAP) tools in CodeBuild stages.

Unit/Integration Tests: Add more comprehensive tests for the Node.js application.

Containerization: Migrate the application to Docker containers and deploy to Amazon ECS or EKS using CodeDeploy Blue/Green deployments.

Blue/Green Deployments: Implement more advanced deployment strategies (e.g., blue/green, canary) with load balancers (ALB) and CodeDeploy.

Infrastructure Testing: Add automated tests for CloudFormation templates (e.g., cfn-lint, cfn-nag).

Monitoring & Alarms: Integrate CloudWatch Alarms for application health and trigger CodeDeploy rollbacks.

Security Hub & GuardDuty: Connect security findings from integrated tools to AWS Security Hub.

Compliance & Governance: Deep dive into AWS Config rules and AWS Organizations policies.

Cost Optimization: Implement autoscaling for EC2 instances, explore Spot Instances, or transition to serverless compute (AWS Lambda).



+---------------------+
|    AWS CloudWatch   |
|  Logs & Events      |
+----------+----------+
|
v
+------------+       +-------------+     +-------------------+
| Developers | ----> | GitHub      | --->|    AWS CodePipeline  |
+------------+       | (CodeSource)|     | (Orchestration)    |
+-------------+     +-------------------+
|
| Source
v
+-------------------+
|    AWS CodeBuild  |
|  (Build - Security|
|  Scan Simulation) |
+-------------------+
|
| Build Artifact
v
+-------------------+
|    AWS CodeBuild  |
|  (Build - App &   |
|  Mock Test)       |
+-------------------+
|
| App Artifact
v
+-------------------+
|    Manual Approval|
| (Staging Promotion)|
+-------------------+
|
|  SNS Notification
v
+-------------------+
|    AWS CodeDeploy |
| (Deploy to Staging)|
+-------------------+
|
v
+---------------------+
|    EC2 Instance     |
|   (Staging - Ubuntu)|
+---------------------+
|
| App deployed at
| http://:3000
v
+-------------------+
|    Manual Approval|
| (Production Promotion)|
+-------------------+
|
| SNS Notification
v
+-------------------+
|    AWS CodeDeploy |
| (Deploy to Production)|
+-------------------+
|
v
+---------------------+
|    EC2 Instance     |
|   (Production - Ubuntu)|
+---------------------+

+-----------------------------------------------------------+
|  Supporting Services:                                     |
|  - AWS IAM (Roles & Policies)                             |
|  - AWS S3 (CodePipeline Artifact Store)                   |
|  - AWS VPC (Network Infrastructure)                       |
+-----------------------------------------------------------+






graph TD
    subgraph Developers
        DEV[Developers]
    end

    subgraph AWS_CloudWatch
        CW_LOGS{CloudWatch Logs & Events}
    end

    subgraph Supporting_Services
        IAM[AWS IAM (Roles & Policies)]
        S3[AWS S3 (CodePipeline Artifact Store)]
        VPC[AWS VPC (Network Infrastructure)]
    end

    DEV --> GITHUB[GitHub (Code Source)]
    GITHUB --> CP[AWS CodePipeline<br>(Orchestration)]

    CP -- Source --> CB_SCAN[AWS CodeBuild<br>(Build - Security Scan Simulation)]
    CB_SCAN -- Build Artifact --> CB_BUILD[AWS CodeBuild<br>(Build - App & Mock Test)]
    CB_BUILD -- App Artifact --> APPROVE_STAGING[Manual Approval<br>(Staging Promotion)]

    APPROVE_STAGING -- SNS Notification --> CP
    CP --> CD_STAGING[AWS CodeDeploy<br>(Deploy to Staging)]

    CD_STAGING --> EC2_STAGING[EC2 Instance<br>(Staging - Ubuntu)]
    EC2_STAGING -- App deployed at<br>http://IP:3000 --> APPROVE_PROD[Manual Approval<br>(Production Promotion)]

    APPROVE_PROD -- SNS Notification --> CP
    CP --> CD_PROD[AWS CodeDeploy<br>(Deploy to Production)]

    CD_PROD --> EC2_PROD[EC2 Instance<br>(Production - Ubuntu)]

    CD_STAGING -- Logs --> CW_LOGS
    CD_PROD -- Logs --> CW_LOGS
    CB_SCAN -- Logs --> CW_LOGS
    CB_BUILD -- Logs --> CW_LOGS





Author
Mohammad Amin Amini

GitHub Profile (https://github.com/4Min4m)

LinkedIn Profile (https://www.linkedin.com/in/mohammad-amin-amini)