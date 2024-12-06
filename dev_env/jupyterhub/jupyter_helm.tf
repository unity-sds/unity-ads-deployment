resource "helm_release" "jupyter_helm" {
  name       = "jupyterhub"
  repository = "https://jupyterhub.github.io/helm-chart"
  chart      = "jupyterhub"
  namespace  = "jhub-${var.deployment_name}-${var.venue}"
  version    = "3.1.0"
  timeout    = 3600

  cleanup_on_fail  = true
  create_namespace = true

  values = [
    templatefile("${path.module}/jupyter_config.yaml", {
      cognito_oauth_base_url = var.cognito_oauth_base_url
      oauth_client_id        = var.cognito_oauth_client_id
      oauth_client_secret    = var.cognito_oauth_client_secret
      oauth_callback_url     = module.frontend.jupyter_base_path != "" ? "${module.frontend.jupyter_base_url}/${module.frontend.jupyter_base_path}/hub/oauth_callback" : "${module.frontend.jupyter_base_url}/hub/oauth_callback"
      jupyter_base_path      = module.frontend.jupyter_base_path != "" ? "/${module.frontend.jupyter_base_path}/" : "/"
      jupyter_base_url       = module.frontend.jupyter_base_url
      jupyter_proxy_port     = var.jupyter_proxy_port
      shared_volume_name     = "${kubernetes_persistent_volume.dev_support_shared_volume.metadata.0.name}"
      unity_auth_py          = base64encode(file("${path.module}/unity_auth.py"))
      # Use jsencode instead of yamlencode so we always have an inline list instead of the yaml multi-line list
      admin_users            = jsonencode(var.jupyter_admin_users)
    })
  ]

  # Need to wait for ALB to get created
  depends_on = [
    module.frontend,
    module.eks,
    kubernetes_storage_class.efs_storage_class,
    kubernetes_storage_class.ebs_storage_class,
    aws_eks_addon.efs-csi,
    aws_eks_addon.ebs-csi,
    module.efs_csi_irsa_role,
    module.ebs_csi_irsa_role,
    kubernetes_persistent_volume.dev_support_shared_volume,
    null_resource.eks_post_deployment_actions
  ]
}

output "kube_namespace" {
  value = helm_release.jupyter_helm.namespace
}
