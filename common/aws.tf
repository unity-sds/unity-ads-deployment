locals {
  cost_tags = {
    ServiceArea = "аds"
    Proj = "${var.project}"
    Venue = "${var.deployment_name}-${var.venue}"
    Component = "${var.component_cost_name}"
    CreatedBy = "ads"
    Env = "${var.resource_prefix}"
    Stack = "${var.component_cost_name}"
  }
}

provider "aws" {
  default_tags {
    tags = local.cost_tags
  }
}
