data "aws_region" "current" {}

locals {
  default_host_management_role = trimprefix("${var.default_host_management_role_path}${var.default_host_management_role_name}", "/")

  ssm_service_settings = {
    "/ssm/managed-instance/default-ec2-instance-management-role" : local.default_host_management_role
    "/ssm/opsitem/ssm-patchmanager" : "Enabled"
    "/ssm/opsitem/EC2" : "Enabled"
    "/ssm/opsdata/ConfigCompliance" : "Enabled"
    "/ssm/opsdata/Association" : "Enabled"
    "/ssm/opsdata/OpsData-TrustedAdvisor" : "Enabled"
    "/ssm/opsdata/ComputeOptimizer" : "Enabled"
    "/ssm/opsdata/SupportCenterCase" : "Enabled"
    "/ssm/opsdata/ExplorerOnboarded" : "true"
  }
}

resource "aws_ssm_service_setting" "ssm_service_settings" {
  for_each = toset(keys(local.ssm_service_settings))

  setting_id    = "arn:aws:ssm:${data.aws_region.current.name}:${local.account_id}:servicesetting${each.key}"
  setting_value = local.ssm_service_settings[each.key]

  lifecycle {
    precondition {
      condition     = can(local.ssm_service_settings[each.key])
      error_message = "The setting \"${each.key}\" is not recognized as a valid SSM service setting for Default Host Management."
    }
  }
}

resource "aws_ssm_association" "update_ssm_agent" {
  name                = "AWS-UpdateSSMAgent"
  association_name    = "UpdateSSMAgent-do-not-delete"
  schedule_expression = "rate(14 days)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}
