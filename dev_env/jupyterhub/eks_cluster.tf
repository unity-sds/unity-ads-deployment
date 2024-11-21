data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

data "aws_ssm_parameter" "ami_id" {
  name = "/mcp/amis/aml2-eks-1-30"
}

#data "external" "current_ip" {
#  program = ["./get_ip.sh"]
#}
#
#resource "aws_security_group" "mc_instance_k8s_api_access" {
#  name        = "${var.resource_prefix}-${var.venue_prefix}${var.venue}-mc-sg"
#  description = "Security group to allow access to K8s API from MC instance"
#
#  vpc_id = data.aws_ssm_parameter.vpc_id.value
#
#  tags = {
#    Name = "${var.resource_prefix}-${var.venue_prefix}${var.venue}-mc-sg"
#  }
#
#  # Allow all outbound traffic.
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  # Allow from variable defined input port
#  ingress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["${data.external.current_ip.result.ip}/32"]
#  }
#
#}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.resource_prefix}-${var.venue_prefix}${var.venue}-jupyter"
  cluster_version = "1.30"

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  subnet_ids       = local.subnet_map["private"]

  vpc_id = data.aws_ssm_parameter.vpc_id.value

  enable_irsa = true

  create_iam_role = true
  iam_role_name = "Unity-ADS-${var.venue_prefix}${var.venue}-EKSClusterRole"
  iam_role_permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/mcp-tenantOperator-AMI-APIG"

  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  enable_cluster_creator_admin_permissions = true

  # add MC instance access to K8s API
  #cluster_additional_security_group_ids = [aws_security_group.mc_instance_k8s_api_access.id]

  eks_managed_node_group_defaults = {
    create_iam_role = true
    iam_role_name = "Unity-ADS-${var.venue_prefix}${var.venue}-EKSNodeRole"
    iam_role_permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/mcp-tenantOperator-AMI-APIG"

    ami_id          = data.aws_ssm_parameter.ami_id.value

    # This seemes necessary so that MCP EKS ami images can communicate with the EKS cluster
    enable_bootstrap_user_data = true
    pre_bootstrap_user_data = <<-EOT
      sudo sed -i 's/^net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf && sudo sysctl -p |true
    EOT

    # Ensure that cost tags are applied to dynamically allocated resources
    launch_template_tags = local.cost_tags
  }

  eks_managed_node_groups = {
    jupyter = {
      instance_types = var.eks_node_instance_types
      disk_size      = var.eks_node_disk_size
      min_size       = var.eks_node_min_size
      max_size       = var.eks_node_max_size
      desired_size   = var.eks_node_desired_size
    }
  }

}

resource "null_resource" "eks_post_deployment_actions" {
  depends_on = [module.eks]
  provisioner "local-exec" {
    command = "./eks_post_deployment_actions.sh ${data.aws_region.current.name} ${module.eks.cluster_name}"
  }
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
