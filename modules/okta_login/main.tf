# --- Okta: Native login app (user auth for P0 web app and CLI) ---
# Import: terraform import 'module.okta_login.okta_app_oauth.p0_login' <app-id>
resource "okta_app_oauth" "p0_login" {
label                      = var.native_app.app_name
type                       = "native"
token_endpoint_auth_method = "none"
pkce_required              = true
grant_types = [
  "authorization_code",
  "urn:ietf:params:oauth:grant-type:token-exchange",
  "urn:ietf:params:oauth:grant-type:device_code"
]
response_types            = ["code"]
login_mode                = "DISABLED"
issuer_mode               = "DYNAMIC"
auto_key_rotation         = true
redirect_uris             = var.native_app.app_redirect_uris
post_logout_redirect_uris = []
logo_uri                  = "https://p0.dev/favicon.ico"
implicit_assignment       = coalesce(var.native_app.implicit_assignment, false)
omit_secret               = true
}
