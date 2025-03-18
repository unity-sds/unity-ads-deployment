# Based on example here:
# https://github.com/terraform-aws-modules/terraform-aws-iam/blob/25e2bf9f9f4757a7014b55db981be9d2beeab445/examples/iam-role-for-service-accounts-eks/main.tf#L372
#
# Debugging steps:
# https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html

locals {
    s3_buckets_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": [ for bucket_name in var.jupyter_s3_buckets :
	                  "arn:aws:s3:::${bucket_name}" ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": [ for bucket_name in var.jupyter_s3_buckets :
	                  "arn:aws:s3:::${bucket_name}/*" ]
        }
      ]
   })

   empty_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "none:null",
            "Resource": "*"
        }
      ]
   })
}

resource "aws_iam_policy" "s3_access_policy" {
  name = "Unity-ADS-${local.deployment_name}${var.venue}-JupyterS3Policy"

  # If no s3 buckets are defined in the variable supply a dummy policy
  policy = length(var.jupyter_s3_buckets) > 0 ?  local.s3_buckets_policy : local.empty_policy
}

module "s3_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "Unity-ADS-${local.deployment_name}${var.venue}-S3ServiceAccount"

  role_policy_arns = {
    policy = aws_iam_policy.s3_access_policy.arn
  }

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = [ "${helm_release.jupyter_helm.namespace}:s3-access" ]
    }
  }

  role_permissions_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/mcp-tenantOperator-AMI-APIG"
}

# Create the Kubernetes service account which will assume the AWS IAM role
resource "kubernetes_service_account" "s3_service_account" {
  metadata {
    name      = "s3-access"
    namespace = helm_release.jupyter_helm.namespace
    annotations = {
      # This annotation is needed to tell the service account which IAM role it
      # should assume
      "eks.amazonaws.com/role-arn" = module.s3_irsa_role.iam_role_arn
    }
  }
}
