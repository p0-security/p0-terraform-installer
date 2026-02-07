terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  tags = {
    managed-by = "terraform"
    used-by    = "P0Security"
  }
}

# This SSM command document is executed by P0 to manage the sudoers file and grant / revoke sudo
# access to a user. The document is created by the customer, P0 is not allowed to create documents
# that it can execute because that is a privilege escalation path.
resource "aws_ssm_document" "p0_manage_sudo_access" {
  name            = "P0ProvisionUserAccess"
  document_format = "YAML"
  document_type   = "Command"
  target_type     = "/AWS::EC2::Instance"
  content         = file("${path.module}/p0-provision-user-access.yaml")
  tags            = local.tags
}

# This SSM document retrieves SSH host keys from an EC2 instance. The document must be created by the customer as
# P0 is not allowed to create documents that it can execute to guard against privilege escalation.
resource "aws_ssm_document" "p0_get_ssh_host_keys" {
  name            = "P0GetSshHostKeys"
  document_format = "YAML"
  document_type   = "Command"
  target_type     = "/AWS::EC2::Instance"
  content         = file("${path.module}/p0-get-ssh-host-keys.yaml")
  tags            = local.tags
}
