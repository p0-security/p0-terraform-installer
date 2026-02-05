# Module which deploys the P0 Azure IAM Management Integration (incl. SSH)

terraform {
  required_providers {
    p0 = {
      source  = "p0-security/p0"
      version = "0.24.0"
    }
  }
}
# Install P0 Azure IAM Write
resource "p0_azure" "p0_azure_install" {
  directory_id = var.directory_id
}

# Install P0 Azure IAM Write Staged
resource "p0_azure_iam_write_staged" "iam_write_staged" {
  depends_on          = [p0_azure.p0_azure_install]
  subscription_id     = var.subscription_id
}

# Install P0 Azure IAM Write
resource "p0_azure_iam_write" "iam_write" {
  depends_on          = [p0_azure_iam_write_staged.iam_write_staged]
  subscription_id     = var.subscription_id
}

# Install the P0 SSH Azure resource
resource "p0_ssh_azure" "azure" {
  depends_on              = [p0_azure_iam_write.iam_write]
  admin_access_role_id    = var.vm_admin_access_role_id
  standard_access_role_id = var.vm_standard_access_role_id
  bastion_id              = var.azure_bastion_id
  management_group_id     = var.management_group_id
  is_sudo_enabled         = true
}
