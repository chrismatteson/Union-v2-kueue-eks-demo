# Union AI EKS Deployment with Terraform

This project contains Terraform code to deploy Union AI data plane on AWS EKS, split into two separate Terraform projects for proper dependency management.

## Project Structure

```
.
├── infrastructure/       # AWS resources (EKS, VPC, S3, IAM)
│   ├── main.tf
│   ├── variables.tf
│   ├── s3.tf
│   ├── iam.tf
│   ├── outputs.tf
│   └── README.md
├── helm-charts/         # Kubernetes/Helm deployments
│   ├── main.tf
│   ├── variables.tf
│   ├── values.yaml.tpl
│   ├── outputs.tf
│   └── README.md
└── README.md           # This file
```

## Why Two Projects?

Separating infrastructure and Helm deployments solves the chicken-and-egg problem:
1. The EKS cluster must exist before Helm/Kubernetes providers can connect to it
2. The `helm-charts` project reads the `infrastructure` project's state file to get cluster details
3. This allows clean, single-apply deployments without circular dependencies

## Quick Start

### 1. Deploy Infrastructure

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your cluster_name
terraform init
terraform apply
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-2 --name <cluster-name>
kubectl get nodes
```

### 3. Deploy Helm Charts

```bash
cd ../helm-charts
terraform init
terraform apply
```

### 4. Verify Deployment

```bash
kubectl get pods -n unionai
```

## What Gets Created

### Infrastructure Project
- **VPC**: 3 availability zones with public and private subnets
- **EKS Cluster**: Managed Kubernetes cluster
- **Node Group**: Auto-scaling node group (default: t3a.xlarge)
- **S3 Bucket**: `unionai-tenant-production-<clustername>` with encryption and versioning
- **IAM User**: With access keys for S3 access (client ID/secret)
- **IAM Role**: For IRSA (IAM Roles for Service Accounts) with S3 and CloudWatch permissions
- **Secrets Manager**: Secure storage for S3 credentials

### Helm Charts Project
- **Namespace**: `unionai`
- **Helm Release**: Union AI data plane chart from https://unionai.github.io/helm-charts
- **Configuration**: Auto-populated from infrastructure state

## Configuration

### Required Variables (infrastructure)
- `cluster_name` - Name of your EKS cluster (e.g., "kueuedemo")

### Optional Variables
See [infrastructure/README.md](infrastructure/README.md) and [helm-charts/README.md](helm-charts/README.md) for all available variables.

## State Management

Both projects use local state files by default:
- `infrastructure/terraform.tfstate` - Infrastructure state
- `helm-charts/terraform.tfstate` - Helm deployments state

The `helm-charts` project reads the infrastructure state using:
```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "../infrastructure/terraform.tfstate"
  }
}
```

For production, consider using a remote backend like S3 with state locking.

## Accessing Credentials

### View All Outputs
```bash
cd infrastructure
terraform output
```

### Get S3 Credentials
```bash
# From Terraform outputs
terraform output s3_access_key_id
terraform output s3_secret_access_key

# From AWS Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id <cluster-name>-s3-credentials \
  --query SecretString --output text | jq
```

## Cleanup

**Important:** Destroy in reverse order to avoid dependency issues.

```bash
# 1. Destroy Helm charts first
cd helm-charts
terraform destroy

# 2. Destroy infrastructure
cd ../infrastructure
terraform destroy
```

## Troubleshooting

### Provider Configuration Issues
If you see errors about Kubernetes/Helm providers not being able to connect:
- Ensure you're in the correct directory (`helm-charts` for Helm, `infrastructure` for AWS)
- Verify the infrastructure has been applied: `cd infrastructure && terraform output`
- Check kubectl access: `kubectl get nodes`

### State File Not Found
If `helm-charts` can't find the infrastructure state:
```bash
ls -la ../infrastructure/terraform.tfstate
```
If the file doesn't exist, apply the infrastructure first.

### Helm Release Fails
Check the Helm release and pod status:
```bash
helm list -n unionai
kubectl get pods -n unionai
kubectl logs -n unionai <pod-name>
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│ VPC (10.0.0.0/16)                               │
│                                                 │
│  ┌──────────────┐  ┌──────────────┐           │
│  │ Public       │  │ Private      │           │
│  │ Subnets      │  │ Subnets      │           │
│  │              │  │              │           │
│  │ NAT Gateway  │  │ EKS Nodes    │           │
│  └──────────────┘  └──────────────┘           │
│                                                 │
│         │                  │                   │
│         │                  │                   │
│         ▼                  ▼                   │
│    Internet           EKS Control              │
│    Gateway            Plane                    │
└─────────────────────────────────────────────────┘
         │
         │
         ▼
    S3 Bucket
    (unionai-tenant-production-*)
         │
         │ IRSA
         ▼
    Union AI Pods
    (with IAM role annotations)
```

## Security Features

- S3 bucket encryption enabled (AES256)
- S3 public access blocked
- Credentials stored in AWS Secrets Manager
- IRSA (IAM Roles for Service Accounts) for pod-level permissions
- Private subnets for EKS nodes
- Security groups managed by EKS module

## Next Steps

After deployment:
1. Access Union AI at `https://<cluster-name>.hosted.unionai.cloud`
2. Configure your workflows to use the S3 bucket
3. Set up monitoring and logging (CloudWatch)
4. Configure backup policies for the S3 bucket

## Support

For issues with:
- **Terraform code**: Check the individual README files in each directory
- **Union AI**: Refer to Union AI documentation
- **AWS EKS**: Check AWS EKS documentation
