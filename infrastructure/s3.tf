# S3 Bucket for Union AI
resource "aws_s3_bucket" "union_tenant" {
  bucket = "unionai-tenant-production-${var.cluster_name}"

  tags = {
    Name        = "unionai-tenant-production-${var.cluster_name}"
    Environment = "production"
    Terraform   = "true"
  }
}

resource "aws_s3_bucket_versioning" "union_tenant" {
  bucket = aws_s3_bucket.union_tenant.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "union_tenant" {
  bucket = aws_s3_bucket.union_tenant.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "union_tenant" {
  bucket = aws_s3_bucket.union_tenant.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Note: IAM User creation is blocked by SCP policy
# Using IRSA (IAM Roles for Service Accounts) only for authentication
# The Union Flyte role in iam.tf provides all necessary S3 access

# Generate random credentials for Helm chart compatibility
# These are placeholder values since we're using IRSA for actual authentication
resource "random_password" "client_id" {
  length  = 20
  special = false
}

resource "random_password" "client_secret" {
  length  = 40
  special = true
}

# Store generated credentials in Secrets Manager
resource "aws_secretsmanager_secret" "s3_credentials" {
  name        = "${var.cluster_name}-s3-credentials"
  description = "Placeholder S3 credentials for ${var.cluster_name} (using IRSA for actual auth)"

  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "s3_credentials" {
  secret_id = aws_secretsmanager_secret.s3_credentials.id
  secret_string = jsonencode({
    client_id     = random_password.client_id.result
    client_secret = random_password.client_secret.result
    bucket_name   = aws_s3_bucket.union_tenant.id
    note          = "Using IRSA authentication - these are placeholder values"
  })
}
