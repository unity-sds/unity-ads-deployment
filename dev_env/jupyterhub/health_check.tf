# Register health check URL
resource "aws_ssm_parameter" "jupyter_health_url" {
  name = "/unity/${var.project}/${var.venue}/component/jupyter"
  type = "String"
  value = jsonencode({
    healthCheckUrl = "${module.frontend.jupyter_base_url}/${module.frontend.jupyter_base_path}/hub/health"
    landingPageUrl = "${module.frontend.jupyter_base_url}/${module.frontend.jupyter_base_path}/"
    componentName  = "Jupyterhub"
  })

  provisioner "local-exec" {
    when = destroy
    command = "${path.module}/eks_pre_destroy_actions.sh"
  }
}
