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
      version = "0.24.0"
    }
  }
  required_version = "= 1.8.0" # version of terraform itself. Recommended to use tfenv to manage terraform versions: https://github.com/tfutils/tfenv
}

# This Okta provider uses private key authentication to authenticate with the Okta API.
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
  okta_org_domain                   = "${var.okta.org_name}.${var.okta.base_url}"
  identity_center_parent_account_id = coalesce(var.identity_center_parent_account_id, data.aws_caller_identity.current.account_id)
}

/**********************************
  Okta Applications
**********************************/
module "okta_native_login" {
  source              = "./modules/okta_native_login"
  app_name            = var.okta.native_app.app_name
  app_redirect_uris   = var.okta.native_app.app_redirect_uris
  implicit_assignment = true
}

module "okta_api_integration_common" {
  source     = "./modules/okta_api_integration_common"
  org_domain = local.okta_org_domain
}

module "okta_api_integration" {
  source                 = "./modules/okta_api_integration"
  org_domain             = local.okta_org_domain
  app_name               = var.okta.api_integration_app.app_name
  p0_org_id              = var.p0.org_id
  p0_lister_role_id      = module.okta_api_integration_common.p0_lister_role_id
  p0_all_users_groups_id = module.okta_api_integration_common.p0_all_users_groups_id
  p0_manager_role_id     = module.okta_api_integration_common.p0_manager_role_id
}

/**********************************
  AWS policy and roles for P0
**********************************/
module "aws_p0_install" {
  source                            = "./modules/aws_p0_install"
  gcp_service_account_id            = var.p0.gcp_service_account_id
  identity_center_parent_account_id = local.identity_center_parent_account_id
}

/**********************************
  AWS roles for P0 access requests
**********************************/
module "aws_p0_roles" {
  source = "./modules/aws_p0_roles"

  saml_identity_provider_name = var.aws.saml_identity_provider_name
  role_count                  = var.aws.role_count
}

/******************************************
  AWS resources for resource-based access
******************************************/
module "aws_p0_resource_access_us_west_1" {
  source = "./modules/aws_p0_resource_access"
  providers = {
    aws = aws.us_west_1
  }
  is_resource_explorer_aggregator = var.regional_aws["us-west-1"].is_resource_explorer_aggregator
}

module "aws_p0_resource_access_us_west_2" {
  source = "./modules/aws_p0_resource_access"
  providers = {
    aws = aws.us_west_2
  }
  is_resource_explorer_aggregator = var.regional_aws["us-west-2"].is_resource_explorer_aggregator
}

/******************************************
  P0 AWS Management Integration
******************************************/
module "p0_aws_iam_management" {
  source              = "./modules/p0_aws_iam_management"
  aws_account_id      = data.aws_caller_identity.current.account_id
  aws_group_key       = var.aws.group_key
  aws_is_sudo_enabled = true
}

/**********************************
  AWS resources for SSH
**********************************/

module "aws_systems_manager" {
  providers = {
    aws.default   = aws
    aws.us_west_1 = aws.us_west_1
    aws.us_west_2 = aws.us_west_2
  }
  source       = "./modules/aws_systems_manager"
  regional_aws = var.regional_aws
}

module "aws_p0_ssm_documents_us_west_1" {
  providers = {
    aws = aws.us_west_1
  }
  source = "./modules/aws_p0_ssm_documents"
}
module "aws_p0_ssm_documents_us_west_2" {
  providers = {
    aws = aws.us_west_2
  }
  source = "./modules/aws_p0_ssm_documents"
}
