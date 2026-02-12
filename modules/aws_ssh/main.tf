# --- AWS: Systems Manager (host management role + regional SSM settings + VPC endpoints) ---
module "systems_manager" {
  source = "./systems_manager"
  providers = {
    aws.default   = aws.default
    aws.us_west_1 = aws.us_west_1
    aws.us_west_2 = aws.us_west_2
  }
  regional_aws = var.regional_aws
}

# --- AWS: P0 SSM documents (per region) ---
module "ssm_documents_us_west_1" {
  source = "./ssm_documents"
  providers = {
    aws = aws.us_west_1
  }
}

module "ssm_documents_us_west_2" {
  source = "./ssm_documents"
  providers = {
    aws = aws.us_west_2
  }
}

# --- P0: AWS SSH integration (requires IAM management to be installed first) ---
# Import: see P0 provider docs for p0_ssh_aws import (if supported).
resource "p0_ssh_aws" "ssh" {
  account_id      = var.aws_account_id
  group_key       = var.aws_group_key
  is_sudo_enabled = var.aws_is_sudo_enabled
}
