variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_instance_type" {
  description = "Instance type for EKS node pool"
  type        = string
  default     = "t3a.xlarge"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "org_name" {
  description = "Organization name"
  type        = string
  default     = "amazon"
}

variable "desired_size" {
  description = "Desired number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 4
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.29"
}
