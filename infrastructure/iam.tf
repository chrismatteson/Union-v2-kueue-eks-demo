# IAM Role for Union Flyte
resource "aws_iam_role" "union_flyte" {
  name = "${var.cluster_name}-union-flyte-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:*:*"
            "${module.eks.oidc_provider}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-union-flyte-role"
    Environment = "production"
    Terraform   = "true"
  }
}

# Attach S3 policy to Union Flyte role
resource "aws_iam_role_policy" "union_flyte_s3" {
  name = "${var.cluster_name}-union-flyte-s3-policy"
  role = aws_iam_role.union_flyte.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.union_tenant.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:DeleteObjectVersion"
        ]
        Resource = [
          "${aws_s3_bucket.union_tenant.arn}/*"
        ]
      }
    ]
  })
}

# Additional permissions for CloudWatch Logs (for fluentbit)
resource "aws_iam_role_policy" "union_flyte_logs" {
  name = "${var.cluster_name}-union-flyte-logs-policy"
  role = aws_iam_role.union_flyte.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = ["arn:aws:logs:${var.region}:*:*"]
      }
    ]
  })
}
