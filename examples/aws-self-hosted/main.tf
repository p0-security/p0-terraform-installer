locals {
  secret_name_prefix = "${var.app_instance}-"
  secrets = [
    "slack-client-secret",
    "azure-ad-client-secret",
    "workspace-client-secret",
    "slack-signing-secret",
    "token-encrypt-key-secret",
    "log-encryption-key",
    "launchdarkly-sdk-key",
    "mailgun-api-key",
    "azure-sso-client-secret",
    "hubspot-api-key",
    "jira-client-secret",
    "ms-teams-client-secret",
    "pagerduty-client-secret"
  ]
  kubernetes_service_accounts = [
    "api", "assessment", "jit", "refresh-cache", "tenant"
  ]
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "app" {
  description             = "Used by ${var.app_instance} for DocumentDB and secrets."
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "DefaultAllow"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = ["kms:*"]
        Resource = "*"
      }
    ]
  })
}
resource "aws_kms_alias" "app" {
  name          = "alias/${var.app_instance}"
  target_key_id = aws_kms_key.app.key_id
}


module "document_db" {
  source = "./document-db"

  cluster_name               = var.app_instance
  kms_key_arn                = aws_kms_key.app.arn
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.private_subnet_ids
  allowed_security_group_ids = var.allowed_security_group_ids
}


resource "aws_secretsmanager_secret" "app" {
  for_each = toset(local.secrets)

  name       = "${local.secret_name_prefix}${each.key}"
  kms_key_id = aws_kms_key.app.arn
}


resource "aws_iam_role" "kubernetes_service_account" {
  for_each = toset(local.kubernetes_service_accounts)

  name               = "${var.app_instance}-ksa-${var.kubernetes_namespace}-${each.key}"
  description        = "IAM Role to be assumed by a Kubernetes Service Account"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"
      }
      Action   = ["sts:AssumeRoleWithWebIdentity"]
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:aud" = "sts.amazonaws.com"
          "${var.oidc_provider}:sub" = "system:serviceaccount:${var.kubernetes_namespace}:${each.key}"
        }
      }
    }]
  })
}

# Allow Kubernetes Service Accounts to assume the P0 Service Roles
resource "aws_iam_role_policy" "assume_service_role" {
  for_each = toset(local.kubernetes_service_accounts)

  name = "assume_service_role"
  role = aws_iam_role.kubernetes_service_account[each.key].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sts:AssumeRole", "sts:TagSession"]
      Resource = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.app_instance}-P0ServiceRole*"]
    }]
  })
}

# Allow Kubernetes Service Accounts to access secrets in AWS Secrets Manager
resource "aws_iam_role_policy" "secrets" {
  for_each = toset(local.kubernetes_service_accounts)

  name = "secrets"
  role = aws_iam_role.kubernetes_service_account[each.key].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.app.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:${local.secret_name_prefix}*"
      }
    ]
  })
}

# Assume role for P0 Service Roles that allow Kubernetes Service Accounts to assume the role
data "aws_iam_policy_document" "service_role_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [for role in aws_iam_role.kubernetes_service_account : role.arn]
    }

    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

# P0 Service Roles, used to access resources managed by the P0 app
resource "aws_iam_role" "service_role" {
  count = var.service_role_count

  name               = "${var.app_instance}-P0ServiceRole${count.index}"
  assume_role_policy = data.aws_iam_policy_document.service_role_assume_role.json
}

data "aws_iam_policy_document" "service_role_cross_account" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    resources = ["arn:aws:iam::*:role/P0RoleIamManager*"]
  }
}

resource "aws_iam_role_policy" "service_role_cross_account" {
  count = var.service_role_count

  name   = "P0ServiceRoleCrossAccount"
  role   = aws_iam_role.service_role[count.index].id
  policy = data.aws_iam_policy_document.service_role_cross_account.json
}
