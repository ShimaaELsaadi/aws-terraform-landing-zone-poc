resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = var.s3_bucket_name
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name        = "poc-${var.env}-terraform-state-bucket"
  }
}
resource "aws_kms_key" "encryption_bucket_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_bucket_encryption" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.encryption_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
resource "aws_s3_bucket_versioning" "versioning-configuration" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "poc-${var.env}-terraform-lock-table"
    Environment = var.env 
  }
}