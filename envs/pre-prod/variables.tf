
variable "region" {
    description = "The AWS region where pre-prod infrastructure."
    type        = string
    default     = "us-east-1"

  
}
variable "environment" {
  description = "The environment for which the resources are being created (e.g., pre-prod, prod)."
  type        = string
  default     = "pre-prod"
}

