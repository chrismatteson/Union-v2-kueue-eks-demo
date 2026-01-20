terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

# Read infrastructure state
data "terraform_remote_state" "infrastructure" {
  backend = "local"

  config = {
    path = "../infrastructure/terraform.tfstate"
  }
}

provider "aws" {
  region = data.terraform_remote_state.infrastructure.outputs.region
}

# Get EKS cluster information
data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.infrastructure.outputs.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.infrastructure.outputs.cluster_name
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Create namespace for Union AI
resource "kubernetes_namespace" "unionai" {
  metadata {
    name = "unionai"
  }
}

# Union AI Data Plane Helm Chart
resource "helm_release" "unionai_dataplane" {
  name       = "unionai-dataplane"
  repository = "https://unionai.github.io/helm-charts"
  chart      = "dataplane"
  namespace  = kubernetes_namespace.unionai.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml.tpl", {
      cluster_name         = data.terraform_remote_state.infrastructure.outputs.cluster_name
      org_name             = var.org_name
      bucket_name          = data.terraform_remote_state.infrastructure.outputs.s3_bucket_name
      region               = data.terraform_remote_state.infrastructure.outputs.region
      client_id            = data.terraform_remote_state.infrastructure.outputs.s3_access_key_id
      client_secret        = data.terraform_remote_state.infrastructure.outputs.s3_secret_access_key
      union_flyte_role_arn = data.terraform_remote_state.infrastructure.outputs.union_flyte_role_arn
    })
  ]

  depends_on = [kubernetes_namespace.unionai]
}
