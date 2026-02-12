terraform {
  backend "s3" {
    bucket = "mike-d-tf-state"
    key    = "p0-tf-install"
    region = "us-west-2"
  }
  required_providers {
    okta = {
      source  = "okta/okta"
      version = ">= 4.8.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0"
    }
    p0 = {
      source  = "p0-security/p0"
      version = ">= 0.24.0"
    }
  }
  required_version = "= 1.8.0" # version of terraform itself. Recommended to use tfenv to manage terraform versions: https://github.com/tfutils/tfenv
}

# This Okta provider uses private key authentication to authenticate with the Okta API.
#
# Required scopes (okta.tfauth.scopes) are derived from the Okta resources in this repo:
#   - okta_app_oauth (okta_native_login, okta_api_integration)  → okta.apps.manage, okta.apps.read
#   - okta_app_oauth (provider may set app authentication/access policy)     → okta.policies.read, okta.policies.manage
#   - okta_app_oauth_api_scope (assign scopes to API integration) → okta.apps.manage (app grant/scope)
#   - okta_admin_role_custom, okta_resource_set (okta_api_integration_common) → okta.roles.manage, okta.roles.read
#   - okta_app_oauth_role_assignment (assign role to API integration app)   → okta.roles.manage, okta.roles.read
# So the minimum set is: okta.apps.manage, okta.apps.read, okta.roles.manage, okta.roles.read, okta.policies.read, okta.policies.manage
provider "okta" {
  org_name       = var.okta.org_name
  base_url       = var.okta.base_url
  client_id      = var.okta.tfauth.client_id
  scopes         = var.okta.tfauth.scopes
  private_key_id = var.okta.tfauth.private_key_id
  # private_key    = sourced from OKTA_API_PRIVATE_KEY environment variable
  #                  Use the jwk-to-pem.py utility to convert a JWK private key to a PEM private key
}

# Use the standard environment variables to provide credentials of the AWS provider.
# E.g: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN for temporary credentials
provider "aws" {
  region = "us-west-2"
  # alias  = ... The default provider has no alias
}

provider "aws" {
  region = "us-west-1"
  alias  = "us_west_1"
}

provider "aws" {
  region = "us-west-2"
  alias  = "us_west_2"
}

provider "p0" {
  org  = var.p0.org_id
  host = "https://api.p0.app"
}

data "aws_caller_identity" "current" {}

locals {
  tags = {
    managed-by = "terraform"
  }
  okta_org_domain = "${var.okta.org_name}.${var.okta.base_url}"
}

/**********************************
  Okta login (native app for user auth)
**********************************/
module "okta_login" {
  source = "./modules/okta_login"

  org_domain = local.okta_org_domain
  native_app = {
    app_name            = var.okta.native_app.app_name
    app_redirect_uris   = var.okta.native_app.app_redirect_uris
    implicit_assignment = true
  }
}

# /**********************************
#   Okta group listing (API integration app + P0 directory)
# **********************************/
module "okta_group_listing" {
  source = "./modules/okta_group_listing"

  org_domain               = local.okta_org_domain
  api_integration_app_name = var.okta.api_integration_app.app_name
}

# /**********************************
#   AWS IAM management (P0 roles + P0 IAM integration)
# **********************************/
# module "aws_iam_management" {
#   source = "./modules/aws_iam_management"

#   gcp_service_account_id            = var.p0.gcp_service_account_id
#   identity_center_parent_account_id = var.identity_center_parent_account_id
#   saml_identity_provider_name       = var.aws.saml_identity_provider_name
#   role_count                        = var.aws.role_count
# }

# /******************************************
#   AWS resource inventory (Resource Explorer + P0 inventory)
# ******************************************/
# module "aws_resource_inventory" {
#   source = "./modules/aws_resource_inventory"

#   aws_account_id = data.aws_caller_identity.current.account_id
#   tags           = local.tags
#   regional_aws = {
#     "us-west-1" = { is_resource_explorer_aggregator = var.regional_aws["us-west-1"].is_resource_explorer_aggregator }
#     "us-west-2" = { is_resource_explorer_aggregator = var.regional_aws["us-west-2"].is_resource_explorer_aggregator }
#   }

#   providers = {
#     aws           = aws
#     aws.us_west_1 = aws.us_west_1
#     aws.us_west_2 = aws.us_west_2
#   }

#   depends_on = [module.aws_iam_management]
# }

# /**********************************
#   AWS SSH (Systems Manager + SSM documents + P0 SSH)
# **********************************/
# module "aws_ssh" {
#   source = "./modules/aws_ssh"

#   regional_aws        = var.regional_aws
#   aws_account_id      = data.aws_caller_identity.current.account_id
#   aws_group_key       = var.aws.group_key
#   aws_is_sudo_enabled = true

#   providers = {
#     aws.default   = aws
#     aws.us_west_1 = aws.us_west_1
#     aws.us_west_2 = aws.us_west_2
#   }

#   depends_on = [module.aws_iam_management]
# }

# /**********************************
#   P0 routing rules
# **********************************/
# module "p0_routing_rules" {
#   source = "./modules/p0_routing_rules"
# }
