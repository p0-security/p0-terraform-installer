locals {
  # Extract cluster identifier and region from ARN
  # ARN format: arn:aws:rds:region:account:cluster:cluster-identifier
  rds_cluster_identifier = split(":", var.rds_instance_arn)[6]

  # TODO region should really come from the staged resource, need to add it to metadata there though
  rds_region = split(":", var.rds_instance_arn)[3]
}

data "aws_rds_cluster" "database" {
  cluster_identifier = local.rds_cluster_identifier
}

data "aws_db_subnet_group" "rds_subnets" {
  name = data.aws_rds_cluster.database.db_subnet_group_name
}

output "resource_id" {
  value = data.aws_rds_cluster.database.cluster_resource_id
}

# Data sources
data "aws_caller_identity" "current" {}

resource "p0_aws_rds" "test" {
  id         = var.vpc_id
  account_id = var.aws_account_id
  region     = local.rds_region
}

# P0 MySQL staged - get Lambda connector metadata
resource "p0_mysql_staged" "test" {
  id           = "test-aurora-mysql"
  instance_arn = var.rds_instance_arn
  vpc_id       = var.vpc_id

  depends_on = [
    p0_aws_rds.test
  ]
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution" {
  name = "P0MysqlPerimeterExecutionRole-${var.vpc_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "P0 RDS Perimeter Lambda Execution Role"
  }
}

# Attach VPC access policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# RDS describe and connect policy for Lambda
resource "aws_iam_role_policy" "lambda_rds_describe" {
  name = "P0RdsSecurityPerimeterDescribePolicy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DescribeRdsInstances"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid    = "ConnectToRdsCluster"
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${local.rds_region}:${var.aws_account_id}:dbuser:${data.aws_rds_cluster.database.cluster_resource_id}/p0_iam_manager"
        ]
      }
    ]
  })
}

# Security group for Lambda
resource "aws_security_group" "lambda" {
  name        = "p0-mysql-rds-security-perimeter-sg"
  description = "Security group allowing traffic from Security Perimeter to RDS"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "p0-mysql-rds-security-perimeter-sg"
  }
}

# Security group for VPC endpoint
resource "aws_security_group" "vpc_endpoint" {
  name        = "p0-mysql-vpc-endpoints-sg"
  description = "Security group allowing all inbound traffic for VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "p0-mysql-vpc-endpoints-sg"
  }
}

# VPC endpoint for RDS
resource "aws_vpc_endpoint" "rds" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.rds_region}.rds"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_db_subnet_group.rds_subnets.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "p0-mysql-rds-vpc-endpoint"
  }
}

# ECR repository for Lambda container image
resource "aws_ecr_repository" "lambda" {
  name                 = "p0-mysql-rds-lambda-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "P0 MySQL RDS Lambda Repository"
  }
}

# Pull and push P0's public image to ECR
resource "terraform_data" "push_lambda_image" {
  provisioner "local-exec" {
    command = <<-EOT
      # Login to ECR
      aws ecr get-login-password --region ${local.rds_region} | \
        docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.rds_region}.amazonaws.com

      # Pull P0's public image
      docker pull p0security/p0-connector-mysql:latest --platform linux/amd64

      # Tag for ECR repository
      docker tag p0security/p0-connector-mysql:latest \
        ${aws_ecr_repository.lambda.repository_url}:latest

      # Push to ECR
      docker push ${aws_ecr_repository.lambda.repository_url}:latest --platform linux/amd64
    EOT
  }

  triggers_replace = {
    repository_url = aws_ecr_repository.lambda.repository_url
  }

  depends_on = [aws_ecr_repository.lambda]
}

# Lambda function (container image)
resource "aws_lambda_function" "mysql_connector" {
  function_name = "p0-mysql-${var.vpc_id}"
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda.repository_url}:latest"
  timeout       = 30
  architectures = ["x86_64"]
  publish       = true

  vpc_config {
    subnet_ids         = data.aws_db_subnet_group.rds_subnets.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_USER = "p0_iam_manager"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_iam_role_policy.lambda_rds_describe,
    aws_vpc_endpoint.rds,
    terraform_data.push_lambda_image
  ]

  tags = {
    Name = "P0 MySQL Connector"
  }
}

# Lambda alias for version management
resource "aws_lambda_alias" "latest" {
  name             = "latest"
  function_name    = aws_lambda_function.mysql_connector.function_name
  function_version = aws_lambda_function.mysql_connector.version
}

# Provisioned concurrency for Lambda
resource "aws_lambda_provisioned_concurrency_config" "connector" {
  function_name                     = aws_lambda_function.mysql_connector.function_name
  provisioned_concurrent_executions = 1
  qualifier                         = aws_lambda_alias.latest.name
}

# Add RDS describe permissions to P0 IAM Manager role for MySQL installation
resource "aws_iam_role_policy" "p0_mysql_rds_describe" {
  name = "P0MysqlRdsDescribePolicy"
  role = "P0RoleIamManager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "P0CanDescribeRdsForMysql"
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction",
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceAccount" = var.aws_account_id
        }
      }
    }]
  })
}

# Complete the MySQL installation
resource "p0_mysql" "test" {
  id           = p0_mysql_staged.test.id
  port         = "3306"
  default_db   = var.db_name
  vpc_id       = var.vpc_id
  instance_arn = var.rds_instance_arn

  depends_on = [
    aws_lambda_function.mysql_connector,
    aws_iam_role_policy.p0_mysql_rds_describe
  ]
}
