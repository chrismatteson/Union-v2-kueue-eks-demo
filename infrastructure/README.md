# Infrastructure - EKS Cluster and AWS Resources

This Terraform project creates the AWS infrastructure for Union AI, including:
- EKS cluster with managed node group
- VPC with public and private subnets
- S3 bucket for Union AI tenant storage
- IAM roles and users for access control
- Secrets Manager for credential storage

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Sufficient AWS permissions to create EKS, VPC, S3, and IAM resources

## Usage

1. **Create terraform.tfvars:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars:**
   ```hcl
   cluster_name = "kueuedemo"
   region       = "us-east-2"
   ```

3. **Initialize and apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Note the outputs** - You'll need these for the helm-charts deployment:
   ```bash
   terraform output
   ```

## Important Outputs

The following outputs are used by the `helm-charts` Terraform project:
- `cluster_name` - EKS cluster name
- `region` - AWS region
- `s3_bucket_name` - S3 bucket for storage
- `s3_access_key_id` - IAM access key ID
- `s3_secret_access_key` - IAM secret access key
- `union_flyte_role_arn` - IAM role ARN for IRSA

## Next Steps

After the infrastructure is created:
1. Configure kubectl:
   ```bash
   aws eks update-kubeconfig --region us-east-2 --name <cluster-name>
   ```

2. Deploy the Helm charts (see `../helm-charts/README.md`)

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the EKS cluster | string | n/a | yes |
| node_instance_type | Instance type for EKS node pool | string | t3a.xlarge | no |
| region | AWS region | string | us-east-2 | no |
| org_name | Organization name | string | amazon | no |
| desired_size | Desired number of nodes | number | 2 | no |
| min_size | Minimum number of nodes | number | 1 | no |
| max_size | Maximum number of nodes | number | 4 | no |
| kubernetes_version | Kubernetes version | string | 1.28 | no |

## Cleanup

To destroy all infrastructure:

```bash
# First, destroy the helm charts
cd ../helm-charts
terraform destroy

# Then destroy the infrastructure
cd ../infrastructure
terraform destroy
```

**Note:** Destroy helm-charts first to avoid issues with resources that depend on the EKS cluster.
