# Module which deploys the P0 AWS IAM Management Integration (incl. SSH)

terraform {
  required_providers {
    p0 = {
      source  = "p0-security/p0"
      version = "0.24.0"
    }
  }
}

# Stages the installation of the P0 GCP IAM Management Integration
resource "p0_aws_iam_write_staged" "iam_write_staged" {
  partition = "aws"
  id        = var.aws_account_id
}

# Finalizes the installation of the P0 AWS IAM Management Integration
resource "p0_aws_iam_write" "iam_write" {
  id         = var.aws_account_id
  depends_on = [p0_aws_iam_write_staged.iam_write_staged]
  partition  = "aws"
  login = {
    type = "idc"
    parent = var.aws_account_id
  }
}

resource "p0_ssh_aws" "ssh" {
  depends_on      = [p0_aws_iam_write.iam_write]
  account_id      = var.aws_account_id
  group_key       = var.aws_group_key
  is_sudo_enabled = var.aws_is_sudo_enabled
}
