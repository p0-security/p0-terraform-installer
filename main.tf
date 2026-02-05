terraform {
  backend "gcs" {
    bucket = "p0-terraform-state-bucket"
    prefix = "p0-tf-install"
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
    azuread = {
      source  = "hashicorp/azuread"
      version = "= 3.1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.18.0"
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
  region = "us-west-1"
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

provider "azuread" {
  tenant_id = var.azure.tenant_id
}

provider "azurerm" {
  features {}
  subscription_id = var.azure.subscription_id
}

provider "p0" {
  org  = var.p0.org_id
  host = "https://api.p0.app"
}

locals {
  tags = {
    managed-by = "terraform"
  }
  okta_org_domain = "${var.okta.org_name}.${var.okta.base_url}"
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

module "okta_aws_federation" {
  source              = "./modules/okta_aws_federation"
  login_app_client_id = module.okta_native_login.client_id

  aws_saml_identity_provider_name = var.aws.saml_identity_provider_name

  app_name       = var.okta.federation_app.app_name
  enduser_note   = var.okta.federation_app.enduser_note
  aws_account_id = var.okta.federation_app.aws_account_id
}


module "okta_api_integration_common" {
  source     = "./modules/okta_api_integration_common"
  org_domain = local.okta_org_domain
}

module "okta_api_integration" {
  source                 = "./modules/okta_api_integration"
  aws_federation_app_id  = module.okta_aws_federation.app_id
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
  source                          = "./modules/aws_p0_install"
  gcp_service_account_id          = var.p0.gcp_service_account_id
  aws_saml_identity_provider_name = var.aws.saml_identity_provider_name
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
  source                     = "./modules/p0_aws_iam_management"
  aws_account_id             = "851725257166"
  aws_okta_federation_app_id = "0oadafqa02Fwhd52V697"
  aws_identity_provider      = "p0dev_okta_saml_multi"
  aws_group_key              = "Stack"
  aws_is_sudo_enabled        = true
}

/******************************************
  P0 GCP Management Integration
******************************************/

resource "p0_gcp" "org" {
  organization_id = var.gcp.organization_id
}

# Deploy the P0 GCP Security Perimeter
module "p0_gcp_security_perimeter" {
  source                = "./modules/p0_gcp_security_perimeter"
  gcp_project_id        = var.gcp.project_id
  location              = var.gcp.location
  p0_project_id         = var.p0.project_id
  service_account_email = p0_gcp.org.service_account_email
  depends_on            = [p0_gcp.org]
}

module "p0_gcp_iam_management" {
  source                   = "./modules/p0_gcp_iam_management"
  gcp_organization_id      = var.gcp.organization_id
  gcp_project_id           = var.gcp.project_id
  gcp_group_key            = "p0-gcp-project/Stack"
  gcp_is_sudo_enabled      = true
  service_account_email    = p0_gcp.org.service_account_email
  security_perimeter_email = module.p0_gcp_security_perimeter.security_perimeter_email
  depends_on               = [module.p0_gcp_security_perimeter]
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
/**********************************
  Azure Bastion Host
**********************************/

module "azure_p0_bastion" {
  source                        = "./modules/azure_p0_bastion"
  tenant_id                     = var.azure.tenant_id
  subscription_id               = var.azure.subscription_id
  region                        = var.azure.region
  resource_group_name           = "p0-terraform-rg"
  bastion_name                  = "terraform-bastion"
  virtual_network_address_space = "15.0.0.0/18"
  bastion_subnet_address_prefix = "15.0.1.0/26"
  bastion_scale_units           = 2
}

/**********************************
  Azure IAM Management Roles
**********************************/
module "azure_p0_roles" {
  source                 = "./modules/azure_p0_roles"
  tenant_id              = var.azure.tenant_id
  subscription_id        = var.azure.subscription_id
  management_group_id    = var.azure.management_group_id
  azure_application_name = "p0-ssh-management"
  gcp_service_account_id = var.p0.gcp_service_account_id
  ssh_only               = true
}

/******************************************
  P0 Azure Management Integration
******************************************/

module "p0_azure_iam_management" {
  source                                   = "./modules/p0_azure_iam_management"
  directory_id                             = var.azure.tenant_id
  subscription_id                          = var.azure.subscription_id
  management_group_id                      = var.azure.management_group_id
  azure_application_registration_client_id = module.azure_p0_roles.registration_client_id
  vm_admin_access_role_id                  = module.azure_p0_roles.vm_admin_access_role_id
  vm_standard_access_role_id               = module.azure_p0_roles.vm_standard_access_role_id
  azure_bastion_id                         = module.azure_p0_bastion.bastion_resource_id
}

/**********************************
  Splunk Audit Logs
**********************************/

module "splunk_audit_logs" {
  source              = "./modules/splunk_audit_logs"
  token_id            = "p0-demo-okta-splunk-hec-token"
  hec_token_cleartext = var.HEC_TOKEN_CLEARTEXT
  hec_endpoint        = "https://hec.p0splunk.ngrok.app"
  index               = "audit_p0"
}
