region = "us-west-1"
project = "self-hosted-runner"
github_repository_name = "test"
github_owner = "aqeelsadiq"


####################################
# ec2 role and ec2 config
###################################
ec2_iam_role = {
  github-runner = {
    iam_role_name = "ssm-ec2-control-role"
    iam_policy_name = "SSM-EC2-Control-Policy"
    ec2_actions   = "ec2:StartInstances,ec2:StopInstances,ssm:GetParameter"
    region        = "us-west-1"
  }
}


ec2_config = {
  ec2_ami        = "ami-07d2649d67dbe8900"
  instance_type  = "t2.micro"
  key_name       = "testec2-aq"
  resource_name  = "GH-runner"
  instance_count = 2
  project = "self-hosted-runner"
  labelname = "self-hosted-runner"
}

###############################
# vpc and subnets
###############################


identifier = {
  vpc            = "my-vpc"
  public_subnet  = "public-subnet"
  private_subnet = "private-subnet"
  igw            = "internet-gateway"
  nat_gateway    = "nat-gateway"
  public_rt      = "public-route-table"
  private_rt     = "private-route-table"
}

vpcs = {
  dev-vpc = {
    cidr   = "10.0.0.0/16"
    region = "us-west-1"

  }
}

pub_subnets = [
  {
    vpc_name = "dev-vpc"
    # name              = "public-1"
    cidr_block        = "10.0.1.0/24"
    availability_zone = "us-west-1a"
    region            = "us-west-1"


  }
]

pri_subnets = [
  {
    vpc_name = "dev-vpc"
    # name              = "private-1"
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-west-1a"
    region            = "us-west-1"

  }
]

####################################
# Security Groups
####################################

security_group = [
  {
    name        = "webserver-sg"
    description = "Allow HTTP and HTTPS"
    ports       = "80,443,22"
    cidr_blocks = "0.0.0.0/0"
    vpc_name    = "dev-vpc"
  }
]


# ######################################
# # lambda function
# ######################################

statement_id = "AllowExecutionFromAPI"
action       = "lambda:InvokeFunction"
principle    = "apigateway.amazonaws.com"


lambda_functions = {
  start-multiple-ec2 = {
    function_name   = "start-multiple-ec2"
    runtime         = "python3.9"
    timeout         = "30"
    handler         = "lambda_function.lambda_handler"
    iam_role_name   = "lambda-ec2-start-role"
    iam_policy_name = "LambdaEC2ControlPolicy"
    ec2_actions     = "ec2:StartInstances,ec2:DescribeInstances,ec2:StopInstances,logs:CreateLogStream,logs:PutLogEvents,logs:CreateLogGroup,ssm:GetParameter"
    region          = "us-west-1"
  }
}




# ###############################
# # api gateway 
# ###############################

api_gateway_config = {
  "ec2-github-api" = {
    api_name         = "ec2-github-api"
    protocol_type    = "HTTP"
    integration_type = "AWS_PROXY"
    auto_deploy      = true
    lambda_action    = "lambda:InvokeFunction"
    lambda_principal = "apigateway.amazonaws.com"
    project          = "self-hosted-runner"
    region           = "us-west-1"
  }
}