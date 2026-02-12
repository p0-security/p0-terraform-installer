output "api_integration_client_id" {
  value       = okta_app_oauth.p0_api_integration.client_id
  description = "Client ID of the P0 Okta API integration service app"
}
