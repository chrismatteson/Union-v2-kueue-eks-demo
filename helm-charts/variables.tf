variable "org_name" {
  description = "Organization name"
  type        = string
  default     = "amazon"
}

variable "client_id" {
  description = "Union client ID for Helm chart"
  type        = string
}

variable "client_secret" {
  description = "Union client secret for Helm chart"
  type        = string
}
