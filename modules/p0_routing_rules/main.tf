/**********************************
  P0 routing rules
**********************************/
# Import: terraform import 'module.p0_routing_rules.p0_routing_rule.aws_any_request_requires_p0_approval' <rule-id>
resource "p0_routing_rule" "aws_any_request_requires_p0_approval" {
  name = "aws-any-request-requires-p0-approval"

  requestor = {
    type = "any"
  }

  resource = {
    type    = "integration"
    service = "aws"
  }

  approval = [{
    type = "p0"
  }]
}

# Import: terraform import 'module.p0_routing_rules.p0_routing_rule.ssh_any_request_requires_p0_approval_with_duration' <rule-id>
resource "p0_routing_rule" "ssh_any_request_requires_p0_approval_with_duration" {
  name = "ssh-any-request-requires-p0-approval-with-duration"

  requestor = {
    type = "any"
  }

  resource = {
    type        = "integration"
    service     = "ssh"
    access_type = "all"
  }

  approval = [{
    type = "p0"
    options = {
      require_duration = true
    }
  }]
}

# Import: terraform import 'module.p0_routing_rules.p0_routing_rule.okta_manager_approval' <rule-id>
resource "p0_routing_rule" "okta_manager_approval" {
  name = "example-okta-manager-approval"

  requestor = {
    type = "any"
  }

  resource = {
    type = "any"
  }

  approval = [{
    type             = "requestor-profile"
    directory        = "okta"
    profile_property = "manager"
    options = {
      require_reason = true
    }
  }]
}

# Import: terraform import 'module.p0_routing_rules.p0_routing_rule.okta_group_approval' <rule-id>
resource "p0_routing_rule" "okta_group_approval" {
  name = "example-okta-group-approval"

  requestor = {
    type = "any"
  }

  resource = {
    type = "any"
  }

  approval = [{
    type   = "group"
    effect = "keep"
    groups = [{
      directory = "okta"
      id        = "00example-group-id"
      label     = "Example Okta Group"
    }]
  }]
}

# Import: terraform import 'module.p0_routing_rules.p0_routing_rule.pagerduty_auto_approval' <rule-id>
resource "p0_routing_rule" "pagerduty_auto_approval" {
  name = "example-pagerduty-auto-approval"

  requestor = {
    type = "any"
  }

  resource = {
    type = "any"
  }

  approval = [{
    type        = "auto"
    integration = "pagerduty"
    options = {
      require_reason = true
    }
  }]
}

# Import: terraform import 'module.p0_routing_rules.p0_routing_rule.escalation_service_approval' <rule-id>
resource "p0_routing_rule" "escalation_service_approval" {
  name = "example-escalation-service-approval"

  requestor = {
    type = "any"
  }

  resource = {
    type = "any"
  }

  approval = [{
    type        = "escalation"
    integration = "pagerduty"
    services    = ["security-escalation"]
    options = {
      require_preapproval = true
    }
  }]
}
