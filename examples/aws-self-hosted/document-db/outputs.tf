# DocumentDB cluster outputs
output "cluster_identifier" {
  description = "DocumentDB cluster identifier"
  value       = aws_docdb_cluster.docdb.cluster_identifier
}

output "cluster_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = aws_docdb_cluster.docdb.endpoint
}

output "cluster_reader_endpoint" {
  description = "DocumentDB cluster reader endpoint"
  value       = aws_docdb_cluster.docdb.reader_endpoint
}

output "cluster_port" {
  description = "DocumentDB cluster port"
  value       = aws_docdb_cluster.docdb.port
}

output "cluster_arn" {
  description = "DocumentDB cluster ARN"
  value       = aws_docdb_cluster.docdb.arn
}

output "cluster_resource_id" {
  description = "DocumentDB cluster resource ID"
  value       = aws_docdb_cluster.docdb.cluster_resource_id
}

output "subnet_group_name" {
  description = "DocumentDB subnet group name"
  value       = aws_docdb_subnet_group.docdb.name
}

# Instance outputs
output "cluster_instances" {
  description = "List of DocumentDB cluster instance identifiers"
  value       = aws_docdb_cluster_instance.cluster_instances[*].identifier
}

output "cluster_instance_endpoints" {
  description = "List of DocumentDB cluster instance endpoints"
  value       = aws_docdb_cluster_instance.cluster_instances[*].endpoint
}

output "master_user_secret_arn" {
  value = aws_docdb_cluster.docdb.master_user_secret[0].secret_arn
}
