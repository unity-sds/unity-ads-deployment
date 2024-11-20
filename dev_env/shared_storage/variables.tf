variable "project" {
  description = "The name of the project matching the /unity/<{project>/<venue</project-name SSM parameter"
  type        = string
  default     = "unity"
}

variable "venue" {
  description = "The name of the unity venue matching the /unity/<project>/<venue>/venue-name SSM parameter"
  type        = string
}

variable "deployment_name" {
  description = "Optional string to place before the venue name in resource names"
  type        = string
  default     = ""
}

variable "resource_prefix" {
  description = "String used at the beginning of the names for all resources to identify them according to the UADS subsystem"
  type        = string
  default     = "uads"
}

variable "efs_identifier" {
  description = "EFS file system to connect Jupyter shared storage with"
  type        = string
  # Example value:uads-development-efs-fs"
}

variable "installprefix" {
  description = "Installation prefix"
  type        = string
  default     = ""
}

variable "tags" {
  type = map(string)
}
