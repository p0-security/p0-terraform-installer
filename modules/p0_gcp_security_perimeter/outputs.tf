output "security_perimeter_email" {
  description = "The P0 Security Perimeter service account email"
  value       = google_service_account.security_perimeter_sa.email
}
