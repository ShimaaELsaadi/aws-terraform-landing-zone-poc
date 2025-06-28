resource "aws_iam_role" "vpc_flow_log_role" {
  name = "poc-${var.environment}-flow-log-role"

    tags = {
        Name        = "poc-${var.environment}-flow-log-role"
        Environment = var.environment
    }
    assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com" 
      }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "vpc_flow_logs_policy" {
  role       = aws_iam_role.vpc_flow_log_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}
