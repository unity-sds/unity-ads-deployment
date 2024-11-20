# The following is necessary for EKS version 1.23 or greater to allow for persistent storage
# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 

################
# EBS CSI add on

module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  role_permissions_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/mcp-tenantOperator-AMI-APIG"

  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = module.ebs_csi_irsa_role.iam_role_arn
  # TODO: uncomment this if you get conflicts
  resolve_conflicts_on_create = "OVERWRITE"
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }

  depends_on = [ module.eks ]
}

################
# EFS CSI add on

data "aws_iam_policy" "efs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

module "efs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "AmazonEKSTFEFSCSIRole-${module.eks.cluster_name}"
  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  role_permissions_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/mcp-tenantOperator-AMI-APIG"

  tags = {
    "eks_addon" = "efs-csi"
    "terraform" = "true"
  }
}

resource "aws_eks_addon" "efs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-efs-csi-driver"
  service_account_role_arn = module.efs_csi_irsa_role.iam_role_arn
  tags = {
    "eks_addon" = "efs-csi"
    "terraform" = "true"
  }

  depends_on = [ module.eks ]
}
