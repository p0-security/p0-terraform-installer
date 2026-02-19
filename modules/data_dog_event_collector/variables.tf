variable "intake_url" {
  type        = string
  description = "Datadog intake URL for audit logs"
}

variable "api_key_cleartext" {
  type        = string
  description = "Datadog API key for audit logs"
  sensitive   = true
}
