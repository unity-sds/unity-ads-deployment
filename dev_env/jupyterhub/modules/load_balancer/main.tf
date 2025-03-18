##########################################################
# Application Load Balancer connecting to the EKS cluster

resource "aws_lb" "jupyter_alb" {
  name               = "jupyter-${var.deployment_name}${var.venue}-alb"
  load_balancer_type = "application"
  security_groups    = [ var.security_group_id ]
  internal           = var.internal
  subnets            = var.lb_subnet_ids

  tags = {
    Name = "${var.resource_prefix}-${var.deployment_name}${var.venue}-jupyter-alb"
  }
}

resource "aws_lb_target_group" "jupyter_alb_target_group" {
  name        = "jupyter-${var.deployment_name}${var.venue}-alb-tg"
  target_type = "instance"
  vpc_id      = var.vpc_id

  protocol         = "HTTP"
  port             = var.jupyter_proxy_port

  tags = {
    name = "${var.resource_prefix}-${var.deployment_name}${var.venue}-alb-target-group"
  }

  # alter the destination of the health check
  health_check {
    path = var.jupyter_base_path != "" ? "/${var.jupyter_base_path}/hub/health" : "/hub/health"
    port = var.jupyter_proxy_port
  }
}

resource "aws_lb_listener" "jupyter_alb_listener" {
  load_balancer_arn = aws_lb.jupyter_alb.arn
  port              = var.load_balancer_port

  protocol          = "HTTP"

  tags = {
    Name = "${var.resource_prefix}-${var.deployment_name}${var.venue}-alb-listener"
  }

  default_action {
    target_group_arn = aws_lb_target_group.jupyter_alb_target_group.arn
    type             = "forward"
  }
}

# Attach eks node_group to load balancer through the autoscaling group
# Solution from here: https://github.com/aws/containers-roadmap/issues/709
resource "aws_autoscaling_attachment" "autoscaling_attachment" {
  autoscaling_group_name = var.autoscaling_group_name
  lb_target_group_arn    = aws_lb_target_group.jupyter_alb_target_group.arn
}
