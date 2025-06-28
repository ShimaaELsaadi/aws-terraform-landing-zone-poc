variable "region" {
  description = "The AWS region where the S3 bucket and DynamoDB table will be created."
  type        = string
  default     = "us-east-1"
}
variable "s3_bucket_name" {
  description = "The name for the S3 bucket to store Terraform state."
  type        = string
  default     = "x-company-terraform-state-bucket-2025-fawry-intern"
}
variable "dynamodb_table_name" {
  description = "The name for the DynamoDB table to store Terraform state locks."
  type        = string
  default     = "x-company-terraform-lock-table-2025-fawry-intern"
}
variable "env" {
  description = "The environment for which the resources are being created (e.g., pre-prod, prod)."
  type        = string
  default     = "pre-prod"
}