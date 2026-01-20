# Changes Made to Fix Deployment Issues

## Issue 1: IAM User Creation Blocked by SCP

### Problem
Your AWS organization has a Service Control Policy (SCP) that explicitly denies IAM user creation:
```
api error AccessDenied: User: arn:aws:sts::371290552455:assumed-role/AWSReservedSSO_UnionAdministratorAccess-1_c48b4845beb12387/chris.matteson@union.ai
is not authorized to perform: iam:CreateUser
```

### Solution
Removed IAM user creation and switched to **IRSA (IAM Roles for Service Accounts) only** for authentication.

#### Changes in `s3.tf`:
- Removed: `aws_iam_user`, `aws_iam_user_policy`, `aws_iam_access_key`
- Added: `random_password` resources to generate placeholder credentials
- The Union Flyte IAM role (in `iam.tf`) provides all S3 access via IRSA
- The placeholder client_id/client_secret are for Helm chart compatibility only

#### How Authentication Works Now:
1. **IRSA**: Kubernetes service accounts are annotated with the Union Flyte IAM role ARN
2. **EKS OIDC**: The EKS cluster's OIDC provider allows pods to assume the IAM role
3. **S3 Access**: Pods use the assumed role credentials (temporary) for S3 access
4. **No Static Keys**: No long-lived access keys are created

This is actually **more secure** than using IAM users with static credentials!

## Issue 2: Kubernetes Version 1.28 Not Supported

### Problem
```
InvalidParameterException: Requested AMI for this version 1.28 is not supported
```

AWS EKS no longer provides AMIs for Kubernetes 1.28.

### Solution
Updated `variables.tf` to use Kubernetes version **1.31** (current supported version).

```hcl
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.31"
}
```

## Updated Outputs

The outputs in `outputs.tf` now reflect the IRSA-based approach:
- `s3_access_key_id` - Now outputs placeholder client_id (for Helm chart compatibility)
- `s3_secret_access_key` - Now outputs placeholder client_secret (for Helm chart compatibility)
- `union_flyte_role_arn` - **This is the actual authentication mechanism**

## Deployment Instructions

Your deployment should now succeed:

```bash
cd infrastructure
terraform init -upgrade  # Upgrade providers
terraform apply
```

After the infrastructure is deployed, continue with the Helm charts:

```bash
cd ../helm-charts
terraform init
terraform apply
```

## Verification

After deployment, verify IRSA is working:

```bash
# Check that service accounts have role annotations
kubectl get sa -n unionai -o yaml | grep eks.amazonaws.com/role-arn

# Check that pods can access S3
kubectl exec -it -n unionai <pod-name> -- aws sts get-caller-identity
```

The pod should show it's using the Union Flyte role ARN, not your user credentials.
