#!/usr/bin/env bash
# Remove from Terraform state everything except the Okta login app (module.okta_login).
# Run from repo root. After this, the resources still exist in Okta/AWS/P0 but Terraform
# will no longer track them. Run terraform apply to recreate them (or delete them manually first).

set -e

terraform state rm 'data.aws_caller_identity.current'
terraform state rm 'module.okta_group_listing'
terraform state rm 'module.aws_iam_management'
terraform state rm 'module.aws_resource_inventory'
terraform state rm 'module.aws_ssh'
terraform state rm 'p0_routing_rule.aws_any_request_requires_p0_approval'
terraform state rm 'p0_routing_rule.ssh_any_request_requires_p0_approval_with_duration'
terraform state rm 'p0_routing_rule.okta_manager_approval'
terraform state rm 'p0_routing_rule.okta_group_approval'
terraform state rm 'p0_routing_rule.pagerduty_auto_approval'
terraform state rm 'p0_routing_rule.escalation_service_approval'

echo "State removal complete. module.okta_login (Okta login app) is still in state."
