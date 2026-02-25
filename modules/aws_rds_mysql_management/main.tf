data "aws_rds_cluster" "database" {
  cluster_identifier = reverse(split(":", var.rds_cluster_arn))[0]
}

data "aws_db_subnet_group" "database" {
  name = data.aws_rds_cluster.database.db_subnet_group_name
}

locals {
  aws_account_id = var.aws_account_id
  aws_iam_role   = var.aws_role_name
  aws_region     = split(":", data.aws_rds_cluster.database.arn)[3]

  rds_id          = data.aws_rds_cluster.database.id
  rds_arn         = data.aws_rds_cluster.database.arn
  rds_resource_id = data.aws_rds_cluster.database.cluster_resource_id
  rds_port        = data.aws_rds_cluster.database.port
  subnet_ids      = data.aws_db_subnet_group.database.subnet_ids
  vpc_id          = data.aws_db_subnet_group.database.vpc_id

  service    = "mysql"
  default_db = "demo"
}

resource "p0_aws_rds" "p0_rds_installation" {
  id         = local.vpc_id
  account_id = local.aws_account_id
  region     = local.aws_region
}

module "aws_rds_vpc" {
  source  = "p0-security/p0-rds-vpc/aws"
  version = "0.1.3"

  aws_role_name = local.aws_iam_role
  vpc_id        = local.vpc_id
}

resource "p0_mysql_staged" "database" {
  id = local.rds_id
  hosting = {
    type         = "aws-rds"
    instance_arn = local.rds_arn
    vpc_id       = local.vpc_id
  }

  depends_on = [
    module.aws_rds_vpc,
    p0_aws_rds.p0_rds_installation
  ]
}

module "aws_mysql_connector" {
  source  = "p0-security/p0-connector/aws"
  version = "0.2.1"

  aws_role_name = local.aws_iam_role
  vpc_id        = local.vpc_id
  connector_arn = p0_mysql_staged.database.hosting.connector_arn

  aws_services       = ["rds"]
  service            = local.service
  service_subnet_ids = local.subnet_ids

  depends_on = [
    module.aws_rds_vpc,
    p0_mysql_staged.database
  ]
}

module "aws_mysql_install" {
  source  = "p0-security/p0-db/aws"
  version = "0.2.1"

  rds_arn                     = local.rds_arn
  connector_security_group_id = module.aws_mysql_connector.connector_security_group.id
  lambda_execution_role_name  = reverse(split("/", reverse(split(":", module.aws_mysql_connector.lambda.role))[0]))[0]
}

resource "p0_mysql" "database" {
  id = p0_mysql_staged.database.id

  default_db = local.default_db
  port       = local.rds_port

  depends_on = [
    module.aws_mysql_connector,
    module.aws_mysql_install
  ]
}
