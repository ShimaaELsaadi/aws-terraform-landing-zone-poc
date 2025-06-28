output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = module.network.subnet_ids
}

output "instances" {
  description = "Details of the EC2 instances"
  value       = {
    instance_ids = module.compute.ec2_instance_ids
    public_ips   = module.compute.ec2_public_ips
    security_group_id = module.compute.security_group_id
    }

}


output "logging_resources" {
  description = "Details of logging resources"
  value       = {
    cloudwatch_log_group = module.logging.cloudwatch_log_group_name
    s3_bucket           = var.environment == "prod" ? module.logging.s3_bucket_arn : "Not created in ${var.environment} environment"
  }
}