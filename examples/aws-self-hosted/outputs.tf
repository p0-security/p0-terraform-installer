output "kubernetes_service_account_role_arns" {
  description = "Map of Kubernetes Service Accounts to the IAM Role ARNs they can assume."
  value = {
    for ksa_name in local.kubernetes_service_accounts : ksa_name => aws_iam_role.kubernetes_service_account[ksa_name].arn
  }
}

output "secretsmanager_secret_arns" {
  description = "Role ARNs of P0 App secrets"
  value = {
    for k, v in aws_secretsmanager_secret.app : k => v.arn
  }
}

output "document_db" {
  description = "DocumentDB Cluster"
  value       = module.document_db
}

output "p0_service_role_arns" {
  description = "Role ARN to set in `config.providers.aws.serviceAccounts` of the p0app helm chart."
  value       = [for k, v in aws_iam_role.service_role : v.arn]
}
