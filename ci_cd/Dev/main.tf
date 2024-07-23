# Anytime this script file is modified run the following terraform commands
# to re-deploy Jenkins:
#   % terraform init          (just run this for the very first time)
#   % terraform fmt           (optional)
#   % terraform validate      (optional)
#   % terraform apply         (to create the services in the cloud)
#   % terraform show          (optional)
#   % terraform state list    (optional)
#   % terraform destroy       (when you don't need the services any longer)
#
# This script has the following variable(s) with no default value(s), hence
# value(s) must be provided for the variable(s) when running terraform:
#   - gl_runner_registration_token:  gitLab registration token for the runner(s)





# Select the provider(s)
#
# Currently (05/07/2024), there are two ways to make the backend configuration
# dynamic.  Please, see https://www.env0.com/blog/terraform-backends.  Here,
# I am using the one that appears to be simpler and requires preprocessing
# with 'sed' command.
#
terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }
  }

  required_version = ">= 0.14"

  backend "local" { path = "Dev-terraform.tfstate" }

}


# Configure the AWS Provider
#
provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      U-ADS   = lower("${local.unity_venue}_env")
    }
  }
}





# LOCALS

locals {
  #  gl_exec_ids = ["shell", "docker"]
  gl_exec_ids = ["shell"]
}

locals {
  unity_venue = "Dev"
}

locals {
  unity_rest_api_name = "Unity API Gateway"
}





# VARIABLES

# Some software versions installed in EC2 instance

variable "app_pack_gen_version" {
  description = "The version (tag) of app-pack-generator to install"
  type        = string
  default     = "0.4.0"
}

variable "unity_app_gen_version" {
  description = "The version (tag) of unity-app-generator to install"
  type        = string
  default     = "0.3.0"
}



# System info: os, hardware

variable "gl_runner_machine_name" {
  description = "Name of the machine to be used for GitLab runner"
  type        = string
#  default     = "MCP RHEL 8 CSET 20*"
  default     = "MCP Amazon Linux 2 20*"
}

variable "gl_runner_instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.medium"
}

variable "gl_runner_architecture" {
  description = "Desired architecture for the instance"
  type        = string
  default     = "x86_64"
}


# Runner related info: instance name, runner name, GitLab registration token

variable "gl_runner_instance_base_name" {
  description = "Name of the Unity-ADS GitLab runner instance"
  type        = string
  default     = "unity-ads-gl-runner"
}

variable "gl_runner_base_name" {
  description = "Name of the Unity-ADS GitLab runner executor"
  type        = string
  default     = "unity-ads"
}

variable "gl_runner_registration_token" {
  description = "GitLab registration token for the runner"
  type        = string
  sensitive   = true
}


# Info on cloud environment where runners are deployed.

variable "ingress_rules" {
  type    = list(number)
  default = [22, 80, 443]
}

variable "egress_rules" {
  type    = list(number)
  default = [0]
}


# Secret values

variable "mcp_glu_secrets_file" {
  type      = string
  default   = "../policies/mcp_glu_secrets.json"
}


# For Lambda execution role policies

variable "lambda_exec_role_trust_policy_file" {
  type      = string
  default   = "../policies/aws_lambda_exec_role_trust_policy.json"
}

variable "lambda_exec_role_ec2_network_interface_file" {
  type      = string
  default   = "../policies/CreateNetworkInterface-on-EC2.json"
}

# Some needed lambda layer

# According to some online information, it is not possible
# to obtain the arn of an AWS provided lambda layer through
# terraform "data" feature. The arn is hard coded here.
#
variable "aws_params_and_secrets_layer_arn" {
  type      = string
  default   = "arn:aws:lambda:us-west-2:345057560386:layer:AWS-Parameters-and-Secrets-Lambda-Extension:11"
}





# DATA

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "unity_vpc" {
  filter {
    name   = "tag:Name"
    values = ["Unity-${local.unity_venue}-VPC"]
  }
}

data "aws_subnets" "unity_private_subnets" {
  filter {
    name   = "tag:Name"
    values = ["Unity-${local.unity_venue}-Priv-Subnet*"]
  }
}

data "aws_subnets" "unity_public_subnets" {
  filter {
    name   = "tag:Name"
    values = ["Unity-${local.unity_venue}-Pub-Subnet*"]
  }
}

# The following is needed for lambda execution role.

data "aws_iam_policy" "mcp_boundary_policy" {
  name = "mcp-tenantOperator-AMI-APIG"
}

data "aws_iam_policy" "aws_lambda_basic_exec_role" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy" "aws_xray_write_access" {
  name = "AWSXRayDaemonWriteAccess"
}


# Any of the following two blocks can be used as data source
# for aws ami id.  The first block (commented out) generates
# a list of IDs, and the argument "owners" is required.  The
# second block must narrow down to exactly one ID; otherwise,
# terraform fails.

# Lookup the correct AMI id to use.  Arrange them in descending
# order so that the latest version comes first.  Wherever needed,
# use
#    data.aws_ami_ids.machine_ami.ids[0]
# to access the latest version of the desired AMI id.
#
#data "aws_ami_ids" "machine_ami" {
#  sort_ascending = false
#  owners         = ["<owner id or alias if any alias>"]
#  filter {
#    name   = "name"
#    values = [var.gl_runner_machine_name]
#  }
#  filter {
#    name   = "root-device-type"
#    values = ["ebs"]
#  }
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#  filter {
#    name   = "architecture"
#    values = ["${var.gl_runner_architecture}"]
#  }
#}

# Another way of obtaining the desired AMI id.  Lookup the correct
# AMI id to use.  Set the optional argument "most_recent" to insure
# that we narrow than to no more than one AMI id and the latest
# version.  For aws_ami, the argument "owners" is optional.
# Wherever needed, use
#    data.aws_ami.machine_ami.id
# to access the latest version of the desired AMI id.
#
data "aws_ami" "machine_ami" {
  executable_users = ["self"]
  most_recent      = true
  filter {
    name   = "name"
    values = [var.gl_runner_machine_name]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = [var.gl_runner_architecture]
  }
}


data "aws_api_gateway_rest_api" "unity_rest_api" {
  name = local.unity_rest_api_name
}


data "aws_api_gateway_authorizers" "unity_api" {
  rest_api_id = data.aws_api_gateway_rest_api.unity_rest_api.id
}

# IMPROVE: There could be more than one authorizer.
#
data "aws_api_gateway_authorizer" "unity_api" {
  rest_api_id   = data.aws_api_gateway_rest_api.unity_rest_api.id
  authorizer_id = data.aws_api_gateway_authorizers.unity_api.ids[0]
}



# RESOURCES

# It appears that a security group is necessary for SSM connection.

# Setup the security groups
#
resource "aws_security_group" "gl_runner_security_group" {
  name        = "GitLab Runner Security Group"
  description = "Allow traffic to access GitLab runner instrance"
  vpc_id      = data.aws_vpc.unity_vpc.id
  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_rules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  dynamic "egress" {
    iterator = port
    for_each = var.egress_rules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}


# Create MCP EC2 instance
#
resource "aws_instance" "gl_runner_instance" {
  for_each               = toset(local.gl_exec_ids)
  ami                    = data.aws_ami.machine_ami.id
  instance_type          = var.gl_runner_instance_type
  subnet_id              = data.aws_subnets.unity_private_subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.gl_runner_security_group.id]

  # Download and install gitlab runner
  #
  user_data = templatefile("../install_group_runner_${var.gl_runner_architecture}_${each.key}.tftpl",
    { token      = var.gl_runner_registration_token,
      name       = lower("${var.gl_runner_base_name}-${local.unity_venue}-${each.key}"),
      app_gen_v  = var.app_pack_gen_version,
      uapp_gen_v = var.unity_app_gen_version })

  tags = {
    Name = "${var.gl_runner_instance_base_name}-${each.key}"
  }

}


# Create needed secret related resources
#
# aws secretsmanager delete-secret --secret-id MCP-GLU-Clone --force-delete-without-recovery --region us-west-2
#
resource "aws_secretsmanager_secret" "mcp_glu_clone" {
  name = "MCP-GLU-Clone"
}
#
resource "aws_secretsmanager_secret_version" "mcp_glu_clone" {
  secret_id     = aws_secretsmanager_secret.mcp_glu_clone.id
  secret_string = file(var.mcp_glu_secrets_file)
}


# Create lambda execution role
#
resource "aws_iam_role" "lambda_exec_role" {
  name = "Lambda-Exec--Unity-ADS--MCP-Clone"
  assume_role_policy = file(var.lambda_exec_role_trust_policy_file)
  permissions_boundary = data.aws_iam_policy.mcp_boundary_policy.arn
  managed_policy_arns = [data.aws_iam_policy.aws_lambda_basic_exec_role.arn, data.aws_iam_policy.aws_xray_write_access.arn]
  
  inline_policy {
    name   = "CreateNetworkInterface-on-EC2"
    policy = file(var.lambda_exec_role_ec2_network_interface_file)
  }
  
  inline_policy {
    name = "unity-ads-mcp-cred-access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = ["secretsmanager:GetSecretValue"]
          Resource = aws_secretsmanager_secret.mcp_glu_clone.arn
        },
      ]
    })
  }
}


# Create a lambda layer for PyJWT
#
resource "aws_lambda_layer_version" "lambda_layer_pyjwt" {
  filename   = "../code/lambda-package_for_pyjwt.zip"
  layer_name = "puython_jwt"

  compatible_runtimes = ["python3.9","python3.10","python3.11","python3.12"]
}


# Create lambda function
#
data "archive_file" "python_lambda_package" {  
  type = "zip"  
  source_file = "${path.module}/../code/lambda_function.py" 
  output_path = "lambda_function.zip"
}
#
resource "aws_lambda_function" "ads_clone" {
  function_name    = "Unity-ADS--MCP-Clone"
  role             = aws_iam_role.lambda_exec_role.arn
  
  timeout          = 60
  layers           = [var.aws_params_and_secrets_layer_arn, aws_lambda_layer_version.lambda_layer_pyjwt.arn]

  filename         = data.archive_file.python_lambda_package.output_path
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
  handler          = "lambda_function.lambda_handler"

  runtime          = "python3.12"
  architectures    = ["x86_64"]
  ephemeral_storage {
    size = 1024 # Min 512 MB and the Max 10240 MB
  }

  vpc_config {
    security_group_ids = [aws_security_group.gl_runner_security_group.id]
    subnet_ids = data.aws_subnets.unity_private_subnets.ids
  }
}
#
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ads_clone.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${data.aws_api_gateway_rest_api.unity_rest_api.id}/*/${aws_api_gateway_method.mcp_clone.http_method}${aws_api_gateway_resource.mcp_clone.path}"
}


# Create restful API resource(s), method(s), integration.
# ACB stands for Auto Clone & Build.
#
resource "aws_api_gateway_resource" "ads_acb" {
  rest_api_id = data.aws_api_gateway_rest_api.unity_rest_api.id
  parent_id   = data.aws_api_gateway_rest_api.unity_rest_api.root_resource_id
  path_part   = "ads-acb"
}
#
resource "aws_api_gateway_resource" "mcp_clone" {
  rest_api_id = data.aws_api_gateway_rest_api.unity_rest_api.id
  parent_id   = aws_api_gateway_resource.ads_acb.id
  path_part   = "mcp-clone"
}
#
resource "aws_api_gateway_method" "mcp_clone" {
  rest_api_id   = data.aws_api_gateway_rest_api.unity_rest_api.id
  resource_id   = aws_api_gateway_resource.mcp_clone.id
  http_method   = "GET"
  
  authorization = "CUSTOM" 
  authorizer_id = data.aws_api_gateway_authorizer.unity_api.id

  # A map of request query string parameters and headers that
  # should be passed to the integration. For example, the
  # following defines that the header Authorization  must be
  # provided on the request.
  #
  request_parameters = {
    "method.request.header.Authorization" = true
  }
}
#
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = data.aws_api_gateway_rest_api.unity_rest_api.id
  resource_id             = aws_api_gateway_resource.mcp_clone.id
  http_method             = aws_api_gateway_method.mcp_clone.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ads_clone.invoke_arn
}
#
# This is a basic response
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = data.aws_api_gateway_rest_api.unity_rest_api.id
  resource_id = aws_api_gateway_resource.mcp_clone.id
  http_method = aws_api_gateway_method.mcp_clone.http_method
  status_code = "200"
}
#
resource "aws_api_gateway_deployment" "mcp_clone" {
  rest_api_id = data.aws_api_gateway_rest_api.unity_rest_api.id
  stage_name    = lower(local.unity_venue)

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.ads_acb.id,
      aws_api_gateway_resource.mcp_clone.id,
      aws_api_gateway_method.mcp_clone.id,
      aws_api_gateway_integration.integration.id,
      aws_api_gateway_method_response.response_200.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}



# OUTPUT

output "unity_vpc_id" {
  description = "Unity VPC id"
  value       = data.aws_vpc.unity_vpc.id
}

output "unity_private_subnet_ids" {
  description = "Unity private subnet ids"
  value       = data.aws_subnets.unity_private_subnets.ids
}

output "unity_public_subnet_ids" {
  description = "Unity public subnet ids"
  value       = data.aws_subnets.unity_public_subnets.ids
}

output "mcp_machine_ami_id" {
  description = "Desired machine AMI"
  value       = data.aws_ami.machine_ami.id
}

output "gl_runner_instance_id" {
  description = "The ID for the newly created jenkins EC2 instance"
  value = tomap({
    for k, inst in aws_instance.gl_runner_instance : k => inst.id
  })
}

output "gl_runner_public_ip" {
  description = "The ip address for the newly created GitLab runner EC2 instance"
  value = tomap({
    for k, inst in aws_instance.gl_runner_instance : k => inst.public_ip
  })
}

output "unity_rest_api_authorizer_name" {
  description = "Unity API authorizer name"
  value       = data.aws_api_gateway_authorizer.unity_api.name
}

output "unity_rest_api_authorizer_id" {
  description = "Unity API authorizer id"
  value       = data.aws_api_gateway_authorizer.unity_api.id
}

output "unity_rest_api_authorizer_type" {
  description = "Unity API authorizer type"
  value       = data.aws_api_gateway_authorizer.unity_api.type
}
