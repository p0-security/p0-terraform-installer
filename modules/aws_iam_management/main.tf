data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  tags = {
    managed-by = "terraform"
    used-by    = "P0Security"
  }
}

# --- P0: AWS IAM Management (staged + IAM role + finalize) ---
# Import: terraform import 'module.aws_iam_management.p0_aws_iam_write_staged.iam_write_staged' <id>
resource "p0_aws_iam_write_staged" "iam_write_staged" {
  partition = "aws"
  id        = local.account_id
}

# Import: terraform import 'module.aws_iam_management.aws_iam_role.p0_iam_role' <role-name> (from p0_aws_iam_write_staged output)
resource "aws_iam_role" "p0_iam_role" {
  name               = p0_aws_iam_write_staged.iam_write_staged.role.name
  assume_role_policy = p0_aws_iam_write_staged.iam_write_staged.role.trust_policy

  inline_policy {
    name   = p0_aws_iam_write_staged.iam_write_staged.role.inline_policy_name
    policy = var.iam_inline_policy != null ? var.iam_inline_policy : p0_aws_iam_write_staged.iam_write_staged.role.inline_policy
  }

  tags = local.tags
}

# Import: terraform import 'module.aws_iam_management.p0_aws_iam_write.iam_write' <id>
resource "p0_aws_iam_write" "iam_write" {
  id        = local.account_id
  partition = "aws"
  login = {
    type   = "idc"
    parent = local.account_id
  }

  depends_on = [
    aws_iam_role.p0_iam_role,
    p0_aws_iam_write_staged.iam_write_staged,
  ]
}
