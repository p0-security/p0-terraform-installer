# Module which deploys the P0 AWS Resource Inventory integration (Resource Explorer + lister role).
# Creates the IAM role from P0's staged output (trust policy, inline policy, role name) so the role
# matches what P0 expects, then finalizes the inventory.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.42.0"
    }
    p0 = {
      source  = "p0-security/p0"
      version = "0.24.0"
    }
  }
}

# Stages the installation of the P0 AWS Resource Inventory (returns role spec from P0 API).
resource "p0_aws_inventory_staged" "resource_inventory_staged" {
  partition = "aws"
  id        = var.aws_account_id
}

# Create the AWS role using the exact trust policy and inline policy from P0 (no hardcoded audience).
resource "aws_iam_role" "p0_iam_resource_lister" {
  name               = p0_aws_inventory_staged.resource_inventory_staged.role.name
  assume_role_policy = p0_aws_inventory_staged.resource_inventory_staged.role.trust_policy

  inline_policy {
    name   = p0_aws_inventory_staged.resource_inventory_staged.role.inline_policy_name
    policy = p0_aws_inventory_staged.resource_inventory_staged.role.inline_policy
  }

  tags = var.tags
}

# Finalizes the installation of the P0 AWS Resource Inventory after the role exists.
resource "p0_aws_inventory" "resource_inventory" {
  id         = var.aws_account_id
  partition  = "aws"
  depends_on = [aws_iam_role.p0_iam_resource_lister, p0_aws_inventory_staged.resource_inventory_staged]
}
