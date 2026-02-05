okta = {
  org_name = "p0dev"
  base_url = "okta.com"
  tfauth = {
    client_id      = "0oackl84oqFBkdQUR697"
    scopes         = ["okta.agentPools.manage", "okta.agentPools.read", "okta.apiTokens.manage", "okta.apiTokens.read", "okta.appGrants.manage", "okta.appGrants.read", "okta.apps.manage", "okta.apps.read", "okta.authenticators.manage", "okta.authenticators.read", "okta.behaviors.manage", "okta.behaviors.read", "okta.brands.manage", "okta.brands.read", "okta.captchas.manage", "okta.captchas.read", "okta.certificateAuthorities.manage", "okta.certificateAuthorities.read", "okta.clients.manage", "okta.clients.read", "okta.clients.register", "okta.devices.manage", "okta.devices.read", "okta.domains.manage", "okta.domains.read", "okta.emailDomains.manage", "okta.emailDomains.read", "okta.emailServers.manage", "okta.emailServers.read", "okta.enduser.dashboard.manage", "okta.enduser.dashboard.read", "okta.enduser.manage", "okta.enduser.read", "okta.eventHooks.manage", "okta.eventHooks.read", "okta.events.read", "okta.factors.manage", "okta.factors.read", "okta.features.manage", "okta.features.read", "okta.groups.manage", "okta.groups.read", "okta.idps.manage", "okta.idps.read", "okta.inlineHooks.manage", "okta.inlineHooks.read", "okta.linkedObjects.manage", "okta.linkedObjects.read", "okta.logStreams.manage", "okta.logStreams.read", "okta.logs.read", "okta.myAccount.authenticators.manage", "okta.myAccount.authenticators.read", "okta.myAccount.email.manage", "okta.myAccount.email.read", "okta.myAccount.oktaApplications.read", "okta.myAccount.organization.read", "okta.myAccount.phone.manage", "okta.myAccount.phone.read", "okta.myAccount.profile.manage", "okta.myAccount.profile.read", "okta.myAccount.sessions.manage", "okta.networkZones.manage", "okta.networkZones.read", "okta.oauthIntegrations.manage", "okta.oauthIntegrations.read", "okta.policies.manage", "okta.policies.read", "okta.principalRateLimits.manage", "okta.principalRateLimits.read", "okta.profileMappings.manage", "okta.profileMappings.read", "okta.rateLimits.manage", "okta.rateLimits.read", "okta.reports.read", "okta.riskProviders.manage", "okta.riskProviders.read", "okta.roles.manage", "okta.roles.read", "okta.schemas.manage", "okta.schemas.read", "okta.sessions.manage", "okta.sessions.read", "okta.templates.manage", "okta.templates.read", "okta.threatInsights.manage", "okta.threatInsights.read", "okta.trustedOrigins.manage", "okta.trustedOrigins.read", "okta.uischemas.manage", "okta.uischemas.read", "okta.userTypes.manage", "okta.userTypes.read", "okta.users.manage", "okta.users.read"]
    # private_key_id = "U4Xkmy2gWK3FY-THFx6bfkD8FQ3HE8Mm3MGbiOsCUio"
    private_key_id = "JLER1-yHQxhHz3UIlusQ2YCTTvKwtg9HQtCGPKWKMuk"
    # Set the OKTA_API_PRIVATE_KEY environment variable to the private key value starting with ----BEGIN PRIVATE KEY----
    # Use the jwk-to-pem.py utility to convert a JWK private key to a PEM private key
  }
  native_app = {
    app_name          = "P0 Login (p0-demo-okta)"
    app_redirect_uris = ["https://p0.app/oidc/auth/_redirect"]
  }
  federation_app = {
    app_name       = "AWS Account Federation (p0-demo-okta)"
    enduser_note   = "p0-demo-okta-saml AWS account in p0-demo-okta production tenant"
    aws_account_id = "533267270629"
  }
  api_integration_app = {
    app_name = "P0 Okta Integration (p0-demo-okta)"
  }
}

p0 = {
  org_id                 = "p0-demo-okta"
  project_id             = "p0-prod"
  gcp_service_account_id = "102346994864456724606"
}

// Note: After changing the role count, the roles must be synced into Okta using the "Refresh Application Data" button.
// button. Syncing is not possible via the Okta API - that is why we use a pre-created pool of roles.
// https://support.okta.com/help/s/article/Refresh-Application-Data-Functionality-and-Usage?language=en_US
aws = {
  saml_identity_provider_name = "p0dev_okta_saml_multi"
  role_count                  = 20
}

regional_aws = {
  us-west-1 = {
    enabled_vpcs                    = ["vpc-07ec677538ae486ad"]
    is_resource_explorer_aggregator = false
  }
  us-west-2 = {
    enabled_vpcs                    = ["vpc-03b9e080f9fc604a7", "vpc-0a995499cf813b5b6"]
    is_resource_explorer_aggregator = true
  }
}

gcp = {
  organization_id = "698375260981"
  project_id      = "p0-demo"
  location        = "us-west1"
}

azure = {
  tenant_id              = "58bc3f15-980d-4b4d-ae2c-fe8f72dc899b"
  management_group_id    = "development-group"
  subscription_id        = "ad1e5b28-ccb7-4bfd-9955-ec0e16b8ae66"
  azure_application_name = "terraform-app"
  ssh_only               = true
  region                 = "West US 2"
}
