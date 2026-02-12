locals {
  tags = {
    managed-by = "terraform"
  }
}

# --- AWS: Resource Explorer index and view (us-west-1) ---
# Import: terraform import 'module.aws_resource_inventory.aws_resourceexplorer2_index.us_west_1' us-west-1
resource "aws_resourceexplorer2_index" "us_west_1" {
  provider = aws.us_west_1
  type     = var.regional_aws["us-west-1"].is_resource_explorer_aggregator ? "AGGREGATOR" : "LOCAL"
  tags     = local.tags

  lifecycle {
    ignore_changes = [type]
  }
}

# Import: terraform import 'module.aws_resource_inventory.aws_resourceexplorer2_view.us_west_1[0]' <view-arn>
resource "aws_resourceexplorer2_view" "us_west_1" {
  count    = var.regional_aws["us-west-1"].is_resource_explorer_aggregator ? 1 : 0
  provider = aws.us_west_1

  name          = "all-resources-p0"
  default_view  = true
  tags          = local.tags
  depends_on    = [aws_resourceexplorer2_index.us_west_1]

  included_property {
    name = "tags"
  }
}

# --- AWS: Resource Explorer index and view (us-west-2) ---
# Import: terraform import 'module.aws_resource_inventory.aws_resourceexplorer2_index.us_west_2' us-west-2
resource "aws_resourceexplorer2_index" "us_west_2" {
  provider = aws.us_west_2
  type     = var.regional_aws["us-west-2"].is_resource_explorer_aggregator ? "AGGREGATOR" : "LOCAL"
  tags     = local.tags

  lifecycle {
    ignore_changes = [type]
  }
}

# Import: terraform import 'module.aws_resource_inventory.aws_resourceexplorer2_view.us_west_2[0]' <view-arn>
resource "aws_resourceexplorer2_view" "us_west_2" {
  count    = var.regional_aws["us-west-2"].is_resource_explorer_aggregator ? 1 : 0
  provider = aws.us_west_2

  name          = "all-resources-p0"
  default_view  = true
  tags          = local.tags
  depends_on    = [aws_resourceexplorer2_index.us_west_2]

  included_property {
    name = "tags"
  }
}

# --- P0: AWS Resource Inventory (staged + IAM role + finalize) ---
# Import: see P0 provider docs for p0_aws_inventory_staged import (if supported).
resource "p0_aws_inventory_staged" "resource_inventory_staged" {
  partition = "aws"
  id        = var.aws_account_id
}

# Import: terraform import 'module.aws_resource_inventory.aws_iam_role.p0_iam_resource_lister' <role-name> (from p0_aws_inventory_staged output)
resource "aws_iam_role" "p0_iam_resource_lister" {
  provider = aws
  name     = p0_aws_inventory_staged.resource_inventory_staged.role.name
  assume_role_policy = p0_aws_inventory_staged.resource_inventory_staged.role.trust_policy

  inline_policy {
    name   = p0_aws_inventory_staged.resource_inventory_staged.role.inline_policy_name
    policy = p0_aws_inventory_staged.resource_inventory_staged.role.inline_policy
  }

  tags = var.tags
}

# Import: see P0 provider docs for p0_aws_inventory import (if supported).
resource "p0_aws_inventory" "resource_inventory" {
  id         = var.aws_account_id
  partition  = "aws"
  depends_on = [aws_iam_role.p0_iam_resource_lister, p0_aws_inventory_staged.resource_inventory_staged]
}
