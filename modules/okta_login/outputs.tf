output "login_app_client_id" {
  value       = okta_app_oauth.p0_login.client_id
  description = "Client ID of the P0 Login OIDC app. Configure as the AWS Account Federation App's \"Allowed Web SSO Client\""
}
