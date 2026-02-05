data "aws_vpc" "current" {
  id = var.vpc_id
}

resource "aws_security_group" "docdb" {
  name        = local.cluster_name
  vpc_id      = var.vpc_id
  description = "Security group for DocumentDB cluster"
}

# DocumentDB subnet group
resource "aws_docdb_subnet_group" "docdb" {
  name       = local.cluster_name
  subnet_ids = var.subnet_ids
}

# DocumentDB parameter group for production settings
resource "aws_docdb_cluster_parameter_group" "docdb" {
  family = "docdb5.0"
  name   = local.cluster_name

  parameter {
    name  = "audit_logs"
    value = "enabled"
  }

  parameter {
    name  = "profiler"
    value = "enabled"
  }

  parameter {
    name  = "profiler_threshold_ms"
    value = "100"
  }
}

resource "aws_vpc_security_group_ingress_rule" "self" {
  description                  = "Allow access to ${local.cluster_name} from itself"
  security_group_id            = aws_security_group.docdb.id
  referenced_security_group_id = aws_security_group.docdb.id
  ip_protocol                  = "-1"
  # from_port                    = 27017
  # to_port                      = 27017
}

resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each                     = toset(var.allowed_security_group_ids)
  description                  = "Allow access to ${local.cluster_name} from ${each.value}"
  security_group_id            = aws_security_group.docdb.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 27017
  to_port                      = 27017
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  description       = "Allow outbound access to the VPC"
  security_group_id = aws_security_group.docdb.id

  cidr_ipv4   = data.aws_vpc.current.cidr_block
  ip_protocol = "-1"
}

# DocumentDB cluster
# Eventually in production we'll have to use our own KMS key for encryption and allow rotation.
# nosemgrep: terraform.aws.security.aws-docdb-encrypted-with-cmk.aws-docdb-encrypted-with-cmk
resource "aws_docdb_cluster" "docdb" {
  cluster_identifier              = local.cluster_name
  engine                          = "docdb"
  engine_version                  = var.engine_version
  master_username                 = var.master_username
  manage_master_user_password     = true
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.backup_window
  preferred_maintenance_window    = var.maintenance_window
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.skip_final_snapshot ? null : "${local.cluster_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  kms_key_id                      = var.kms_key_arn
  storage_encrypted               = true
  port                            = 27017
  db_subnet_group_name            = aws_docdb_subnet_group.docdb.name
  vpc_security_group_ids          = [aws_security_group.docdb.id]
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.docdb.name

  enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  # Production safeguards
  deletion_protection         = var.deletion_protection
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately
}

# DocumentDB cluster instances
resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = var.cluster_size
  identifier         = "${local.cluster_name}-${count.index}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = var.instance_class
}
