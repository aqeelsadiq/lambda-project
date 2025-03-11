

#####################################
#  vpc
#####################################
module "vpc" {
  source      = "./modules/vpc"
  vpcs        = var.vpcs
  pub_subnets = var.pub_subnets
  pri_subnets = var.pri_subnets
  project     = var.project
  identifier = var.identifier

}
# ####################################
# # Security Group
# ####################################
module "sg" {
  source  = "./modules/sg"
  vpc_id  = module.vpc.vpc_ids
  project = var.project
  security_group = var.security_group
}


# #####################################
# #  EC2
# #####################################
module "ec2" {
  source = "./modules/ec2"
  ec2_config = var.ec2_config
  ec2_iam_role = var.ec2_iam_role
  vpc_id = module.vpc.vpc_ids
  security_group_ids = module.sg.security_group_ids
  pri_subnet = values(module.vpc.private_subnet_ids)
}

# ######################################
# # lambda
# ######################################

module "lambda" {
  source           = "./modules/lambda"
  lambda_functions = var.lambda_functions
  action           = var.action
  principle        = var.principle
  statement_id     = var.statement_id
  project = var.project
  depends_on = [ module.ec2 ]
}



# ##########################################
# #  apigateway
# ##########################################


module "apigateway" {
  source = "./modules/apigateway"
  api_gateway_config = var.api_gateway_config
  lambda_function_names = module.lambda.lambda_function_names
  lambda_invoke_arns = module.lambda.lambda_invoke_arns
  github_repository_name = var.github_repository_name
  depends_on = [ module.lambda ]
}
