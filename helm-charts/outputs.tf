output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.unionai_dataplane.name
}

output "helm_release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.unionai_dataplane.namespace
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.unionai_dataplane.status
}

output "unionai_host" {
  description = "Union AI host URL"
  value       = "${data.terraform_remote_state.infrastructure.outputs.cluster_name}.hosted.unionai.cloud"
}
