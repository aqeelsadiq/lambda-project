This infrastructure contains Terraform configurations for deploying a self-hosted GitHub Actions runner  on AWS. The setup includes an API Gateway, a Lambda function to start EC2 instances, security groups, and a VPC.

# Infrastructure

This project provisions the following AWS resources:

1. VPC: 
A custom Virtual Private Cloud with subnets.

2. Security Groups: 
Firewall rules to control inbound/outbound traffic.

3. EC2 Instances: 
Self-hosted GitHub Actions runners.

4. API Gateway: 
A RESTful API endpoint to trigger the Lambda function.

5. Lambda Function: 
Starts EC2 instances dynamically based on incoming GitHub webhooks.

# modules Explanation
1. # GitHub Webhook Setup

The GitHub webhook is configured using the Terraform GitHub provider. The token used for authentication is used from the ssm parameter store and data block is mention in provider.tf.

create Fine-grained access token with specific permissions

1. Read access to metadata 

2. Read and Write access to actions, **administration, repository hooks, and workflows**

In the API Gateway module (modules/apigateway/main.tf), the webhook is set up to receive workflow-job events from GitHub and forward them to the Lambda function.

2. # EC2 Instance Configuration

The user_data.sh script performs the following steps:

1. Installs necessary dependencies (AWS CLI, curl, unzip, jq).

2. Retrieves GitHub Owner and Personal Access Token from AWS SSM Parameter Store.

3. Downloads and installs the GitHub Actions runner.

4. Registers the EC2 instance as a self-hosted runner in the GitHub repository.

5. Configures the runner as a system service and starts it.

6. Sets up a cron job (self_stop.sh) to monitor job activity and shut down the instance if no job run for 15 minutes.

In the EC2 module (modules/ec2/user_data.sh), the instance retrieves the GitHub Personal Access Token (PAT) and GitHub Owner details manually set in AWS Systems Manager SSM Parameter Store. The script fetches these values using the AWS CLI.

ec2 instances are in the private subnets.

"**aws ssm get-parameter --name "/lambda/github-owner" --with-decryption --query "Parameter.Value" --output text --region us-west-1**"

3. # Lambda Function Configuration
store the **github-token, github-owner and githubrepo-name** in the system manages parameter store manually. 

use the data block to fetch the all three and use it for lambda function.

The Lambda module fetches the required GitHub credentials using a Terraform data block. These values are stored as environment variables in the Lambda function configuration:

GITHUB_TOKEN: Retrieved from Terraform.

GITHUB_OWNER: Retrieved from Terraform.

REPO_NAME: Retrieved from Terraform.

The Lambda function then uses these environment variables to interact with the GitHub API and determine which EC2 instance to start.

# app
in the app directory i use the lambda function code lambda_function.py and path is given in the module/lambda/main.tf

# Deployment steps

1. aws account and credentials configured
    **aws configure**

2. Terraform installed

3. Githubactions setup to use self-hosted runners

4. initialize terraform
    **terraform init**

5. plan terraform 
    **terraform plan**

6. Apply terraform
    **terraform apply --auto-approve**

# Troubleshooting

1. **Lambda Fails to Start EC2:** Check IAM permissions for the Lambda function.

2. **EC2 Instance Not Registering as Runner:** Ensure the GitHub token is correctly retrieved from SSM. check iam role and permissions.

3. **Webhook Not Triggering:** Verify API Gateway logs and check GitHub webhook settings. check github token permission also.


# Things you must have:

1. Fine-grained access token( Read access to metadata Read and Write access to actions, administration, repository hooks, and workflows)

2. Github account and Github repo.

3. set ssm parameter values of github token, github owner and githubrepo name.
