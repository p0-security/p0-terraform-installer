data "aws_caller_identity" "current" {}

locals {
  tags = {
    managed-by = "terraform"
    used-by    = "P0Security"
  }
}

resource "aws_ssm_document" "p0_manage_sudo_access" {
  name            = "P0ProvisionUserAccess"
  document_format = "YAML"
  document_type   = "Command"
  target_type     = "/AWS::EC2::Instance"
  content         = file("${path.module}/p0-provision-user-access.yaml")
  tags            = local.tags
}

resource "aws_ssm_document" "p0_get_ssh_host_keys" {
  name            = "P0GetSshHostKeys"
  document_format = "YAML"
  document_type   = "Command"
  target_type     = "/AWS::EC2::Instance"
  content         = file("${path.module}/p0-get-ssh-host-keys.yaml")
  tags            = local.tags
}
