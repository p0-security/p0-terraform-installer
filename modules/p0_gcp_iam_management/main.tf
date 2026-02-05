# Module which deploys the P0 AWS IAM Management Integration (incl. SSH)

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.16.0"
    }
    p0 = {
      source  = "p0-security/p0"
      version = "0.24.0"
    }
  }
}

# Enable required GCP services
resource "google_project_service" "enable_services" {
  project            = var.gcp_project_id
  for_each = toset([
    "cloudasset.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "oslogin.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

# This custom role is required for P0 to manage IAM grants in your project
# To import: terraform import module.p0_gcp_iam_management.google_project_iam_custom_role.iam-manager-role projects/{projectId}/roles/p0IamManager
resource "google_project_iam_custom_role" "iam-manager-role" {
  project     = var.gcp_project_id
  role_id     = "p0IamManager"
  title       = "P0 IAM Manager"
  description = "Role used by P0 to manage access to your GCP project"
  permissions = [
      "cloudasset.assets.analyzeIamPolicy",
      "cloudasset.assets.searchAllIamPolicies",
      "cloudasset.assets.searchAllResources",
      "compute.instances.get",
      "iam.roles.create",
      "iam.roles.delete",
      "resourcemanager.projects.get"
  ]
}

# Grants the P0 IAM Manager role to the P0 service account
resource "google_project_iam_member" "iam-manager-role-binding" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.iam-manager-role.id
  member  = "serviceAccount:${var.service_account_email}"
}

# Grants the Security Reviewer role to the P0 service account
resource "google_project_iam_member" "security_reviewer_role_binding" {
  project = var.gcp_project_id
  role    = "roles/iam.securityReviewer"
  member  = "serviceAccount:${var.service_account_email}"
}

# IAM Role for P0 IAM Writer
# To import: terraform import module.p0_gcp_iam_management.google_project_iam_custom_role.iam_writer_role projects/{projectId}/roles/p0IamWriter
resource "google_project_iam_custom_role" "iam_writer_role" {
  role_id     = "p0IamWriter"
  title       = "P0 IAM Writer"
  description = "Role used by P0 security perimeter service account to manage iam in the project"
  project     = var.gcp_project_id
  stage       = "GA"

  permissions = [
    "bigquery.datasets.get",
    "bigquery.datasets.update",
    "iam.serviceAccounts.get",
    "resourcemanager.projects.get"
  ]
}

# Grants the IAM Writer role to the Security Perimeter service account
resource "google_project_iam_member" "iam_writer_role_binding" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.iam_writer_role.id
  member  = "serviceAccount:${var.security_perimeter_email}"
}

# Grants the Security Admin role to the Security Perimeter service account
resource "google_project_iam_member" "security_admin_role_binding" {
  project = var.gcp_project_id
  role    = "roles/iam.securityAdmin"
  member  = "serviceAccount:${var.security_perimeter_email}"
}


# Stages the installation of the P0 GCP IAM Management Integration
# To import: terraform import module.p0_gcp_iam_management.p0_gcp_iam_write_staged.iam_write_staged {projectId}
resource "p0_gcp_iam_write_staged" "iam_write_staged" {
  project  = var.gcp_project_id
}

# Finalizes the installation of the P0 GCP IAM Management Integration
# To import: terraform import module.p0_gcp_iam_management.p0_gcp_iam_write_staged.iam_write {projectId}
resource "p0_gcp_iam_write" "iam_write" {
  project  = var.gcp_project_id
  depends_on = [
    p0_gcp_iam_write_staged.iam_write_staged,
    google_project_iam_custom_role.iam-manager-role,
    google_project_iam_member.iam-manager-role-binding,
    google_project_iam_member.security_reviewer_role_binding,
    google_project_iam_custom_role.iam_writer_role,
    google_project_iam_member.iam_writer_role_binding,
    google_project_iam_member.security_admin_role_binding  ]
}

# Installs the GCP SSH integration
resource "p0_ssh_gcp" "ssh" {
  project_id      = var.gcp_project_id
  group_key       = var.gcp_group_key
  is_sudo_enabled = var.gcp_is_sudo_enabled
  depends_on      = [p0_gcp_iam_write.iam_write]
}
