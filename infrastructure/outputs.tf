output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "s3_bucket_name" {
  description = "S3 bucket name for Union AI tenant"
  value       = aws_s3_bucket.union_tenant.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.union_tenant.arn
}

output "s3_access_key_id" {
  description = "Placeholder client ID for Helm chart (using IRSA for actual auth)"
  value       = random_password.client_id.result
  sensitive   = true
}

output "s3_secret_access_key" {
  description = "Placeholder client secret for Helm chart (using IRSA for actual auth)"
  value       = random_password.client_secret.result
  sensitive   = true
}

output "union_flyte_role_arn" {
  description = "ARN of the IAM role for Union Flyte"
  value       = aws_iam_role.union_flyte.arn
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret containing S3 credentials"
  value       = aws_secretsmanager_secret.s3_credentials.arn
}

output "configure_kubectl" {
  description = "Configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "unionai_host" {
  description = "Union AI host URL"
  value       = "${var.cluster_name}.hosted.unionai.cloud"
}
