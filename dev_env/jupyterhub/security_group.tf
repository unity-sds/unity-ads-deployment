resource "aws_security_group" "jupyter_lb_sg" {
  name        = "${var.resource_prefix}-${local.deployment_name}${var.venue}-lb-sg"
  description = "U-ADS ${local.deployment_name}${var.venue} JupyterHub application load balancer security group"

  vpc_id = data.aws_ssm_parameter.vpc_id.value

  tags = {
    Name = "${var.resource_prefix}-${local.deployment_name}${var.venue}-lb-sg"
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow from variable defined input port
  ingress {
    from_port   = "${local.load_balancer_port}"
    to_port     = "${local.load_balancer_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group_rule" "jupyter_cluster_allow_lb" {
  type                     = "ingress"
  from_port                = "30000"
  to_port                  = "32767"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jupyter_lb_sg.id
  security_group_id        = module.eks.node_security_group_id
}
