# Helm Charts - Union AI Data Plane

This Terraform project deploys the Union AI data plane Helm chart to the EKS cluster created by the `infrastructure` project.

## Prerequisites

- The `infrastructure` Terraform project must be applied first
- kubectl configured to access the EKS cluster
- Helm 3.x installed

## How It Works

This project uses Terraform's `terraform_remote_state` data source to read outputs from the `infrastructure` project's local state file. It automatically retrieves:
- EKS cluster name and endpoint
- S3 bucket name
- IAM credentials
- IAM role ARNs
- AWS region

## Usage

1. **Ensure infrastructure is deployed:**
   ```bash
   cd ../infrastructure
   terraform output  # Verify outputs are available
   cd ../helm-charts
   ```

2. **Create terraform.tfvars (optional):**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars if needed:**
   ```hcl
   org_name = "amazon"  # Default is already "amazon"
   ```

4. **Deploy the Helm chart:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Verify deployment:**
   ```bash
   kubectl get pods -n unionai
   kubectl get helmrelease -A
   ```

## What Gets Deployed

- Kubernetes namespace: `unionai`
- Helm chart: `dataplane` from https://unionai.github.io/helm-charts
- Configuration includes:
  - Union AI host URL
  - S3 storage configuration
  - IAM role annotations for IRSA
  - Admin credentials from infrastructure

## Values Template

The Helm values are generated from [values.yaml.tpl](values.yaml.tpl) and automatically populated with values from the infrastructure state:

```yaml
host: <cluster_name>.hosted.unionai.cloud
clusterName: <cluster_name>
orgName: amazon
provider: aws
storage:
  provider: aws
  authType: iam
  bucketName: <from infrastructure>
  fastRegistrationBucketName: <from infrastructure>
  region: <from infrastructure>
  enableMultiContainer: true
secrets:
  admin:
    create: true
    clientId: <from infrastructure>
    clientSecret: <from infrastructure>
additionalServiceAccountAnnotations:
  eks.amazonaws.com/role-arn: <from infrastructure>
userRoleAnnotationKey: eks.amazonaws.com/role-arn
userRoleAnnotationValue: <from infrastructure>
fluentbit:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: <from infrastructure>
```

## Troubleshooting

### Error: No state file found

If you get an error about missing state file:
```
Error: Error reading state: open ../infrastructure/terraform.tfstate: no such file or directory
```

This means the infrastructure hasn't been deployed yet. Run:
```bash
cd ../infrastructure
terraform apply
cd ../helm-charts
```

### Error: kubectl connection refused

Configure kubectl to access your cluster:
```bash
aws eks update-kubeconfig --region us-east-2 --name <cluster-name>
kubectl get nodes  # Verify connection
```

### Helm release fails

Check the Helm release status:
```bash
helm list -n unionai
helm status unionai-dataplane -n unionai
kubectl describe helmrelease unionai-dataplane -n unionai
```

## Outputs

- `helm_release_name` - Name of the deployed Helm release
- `helm_release_namespace` - Kubernetes namespace
- `helm_release_status` - Deployment status
- `unionai_host` - Union AI host URL

## Cleanup

To remove the Helm chart:

```bash
terraform destroy
```

**Important:** Always destroy the helm-charts before destroying the infrastructure to avoid orphaned resources.
