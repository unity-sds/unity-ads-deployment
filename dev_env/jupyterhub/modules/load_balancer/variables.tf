#############################
# Jupyterlab common variables
# These come from the top level variables

variable "project" {
  description = "The name of the project matching the /unity/<{project>/<venue</project-name SSM parameter"
  type        = string
}

variable "venue" {
  description = "The name of the unity venue matching the /unity/<project>/<venue>/venue-name SSM parameter"
  type        = string
}

variable "deployment_name" {
  description = "Optional string to place before the venue name in resource names"
  type        = string
}

variable "resource_prefix" {
  description = "String used at the beginning of the names for all resources to identify them according to the UADS subsystem"
  type        = string
}

variable "load_balancer_port" {
  description = "Incoming port where load balancer will accept traffic"
  type       = number
}

variable "jupyter_proxy_port" {
  description = "Listening port for Jupyter kubernetes cluster"
  type       = number
}

# Do not supply trailing slashes
variable "jupyter_base_url" {
  description = "Base URL minus path for Jupyter as accessed at its public facing location"
  type       = string
  default    = null
}

# Do not include leading or training slashes
variable "jupyter_base_path" {
  description = "Base path for Jupyter as accessed at its public facing location"
  type       = string
  default    = ""
}

###################################
# Frontend module common variables

variable "vpc_id" {
  description = "VPC id for load balancer target group"
  type        = string
}

variable "internal" {
  description = "If load balancers created should be internal or not"
  type        = bool
}

variable "lb_subnet_ids" {
  description = "Subnet ids for the load balancer"
  type        = list
}

variable "security_group_id" {
  description = "Security group id giving access to load balancer to Jupyter EKS cluster"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Name of the EKS cluster autoscaling group to connect to the front end"
  type        = string
}

###########################
# Module specific variables

# ... None yet ...
