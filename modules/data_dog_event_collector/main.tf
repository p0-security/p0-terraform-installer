/**********************************
  P0 routing rules
**********************************/
# Import: terraform import 'module.data_dog_event_collector.p0_datadog_audit_logs.primary' <rule-id>
resource "p0_datadog_audit_logs" "example" {
  identifier        = "datadog-audit-logs"
  intake_url        = var.intake_url
  api_key_cleartext = sensitive(var.api_key_cleartext)
  service           = "p0"
}
