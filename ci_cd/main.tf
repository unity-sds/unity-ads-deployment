# Anytime this script file is modified run the following terraform commands
# to re-deploy Jenkins:
#   % terraform init          (just run this for the very first time)
#   % terraform fmt           (optional)
#   % terraform validate      (optional)
#   % terraform apply         (to create the services in the cloud)
#   % terraform show          (optional)
#   % terraform state list    (optional)
#   % terraform destroy       (when you don't need the services any longer)


# Select the provider(s)
#
terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }
  }

  required_version = ">= 0.14"

}


# Configure the AWS Provider
#
provider "aws" {
  region = "us-west-2"
}




# VARIABLES


# System info: os, hardware

variable "gl_runner_machine_name" {
  description = "Name of the machine to be used for GitLab runner"
  type        = string
  default     = "MCP Amazon Linux 2 20*"
}

variable "gl_runner_instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.small"
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
}


# Info on cloud environment where runners are deployed.

variable "unity_instance" {
  description = "Name of the Unity instance where deploying"
  type        = string
  default     = "Unity-Dev"
}

#variable "tenant_identifier" {
#  description = "String identifying the tenant for which resources are created"
#  type        = string
#  default     = "development"
#}

variable "ingress_rules" {
  type    = list(number)
  default = [22, 80, 443]
}

variable "egress_rules" {
  type    = list(number)
  default = [0]
}




# DATA

data "aws_vpc" "unity_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.unity_instance}-VPC"]
  }
}

data "aws_subnets" "unity_private_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.unity_instance}-Priv-Subnet*"]
  }
}

data "aws_subnets" "unity_public_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.unity_instance}-Pub-Subnet*"]
  }
}

data "aws_subnets" "unity_public_subnet_nat" {
  filter {
    name   = "tag:Name"
    values = ["${var.unity_instance}-Pub-Subnet01"]
  }
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
    values = ["${var.gl_runner_architecture}"]
  }
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
  user_data = templatefile("./install_group_runner_${var.gl_runner_architecture}_${each.key}.tftpl",
  { token = "${var.gl_runner_registration_token}", name = "${var.gl_runner_base_name}-${each.key}" })

  tags = {
    Name = "${var.gl_runner_instance_base_name}-${each.key}"
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

output "unity_public_subnet_id" {
  description = "Id of Unity public subnet with NAT"
  value       = data.aws_subnets.unity_public_subnet_nat.ids
}

#output "mcp_machine_ami_ids" {
#  description = "Desired machine AMIs"
#  value       = data.aws_ami_ids.machine_ami.ids
#}

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
