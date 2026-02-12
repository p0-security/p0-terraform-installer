locals {
  tags = {
    managed-by = "terraform"
  }
}

# Import: terraform import -provider=aws.default 'module.aws_ssh.module.systems_manager.aws_iam_role.default_host_management_role' AWSSystemsManagerDefaultEC2InstanceManagementRole
resource "aws_iam_role" "default_host_management_role" {
  provider = aws.default

  name        = "AWSSystemsManagerDefaultEC2InstanceManagementRole"
  path        = "/service-role/"
  description = "AWS Systems Manager Default EC2 Instance Management Role"

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"]

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ssm.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

module "region_us_west_1" {
  source = "./modules/region"
  providers = {
    aws = aws.us_west_1
  }

  enabled_vpcs                      = var.regional_aws["us-west-1"].enabled_vpcs
  default_host_management_role_path = aws_iam_role.default_host_management_role.path
  default_host_management_role_name = aws_iam_role.default_host_management_role.name
}

module "region_us_west_2" {
  source = "./modules/region"
  providers = {
    aws = aws.us_west_2
  }

  enabled_vpcs                      = var.regional_aws["us-west-2"].enabled_vpcs
  default_host_management_role_path = aws_iam_role.default_host_management_role.path
  default_host_management_role_name = aws_iam_role.default_host_management_role.name
}
