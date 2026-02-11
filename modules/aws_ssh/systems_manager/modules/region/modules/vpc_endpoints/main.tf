data "aws_region" "current" {}

locals {
  endpoints = tomap({
    s3 = {
      service = "com.amazonaws.${data.aws_region.current.name}.s3",
      type    = "Gateway"
    },
    ssm = {
      service = "com.amazonaws.${data.aws_region.current.name}.ssm",
      type    = "Interface"
    },
    ssmmessages = {
      service = "com.amazonaws.${data.aws_region.current.name}.ssmmessages",
      type    = "Interface"
    },
    ec2 = {
      service = "com.amazonaws.${data.aws_region.current.name}.ec2",
      type    = "Interface"
    },
    ec2messages = {
      service = "com.amazonaws.${data.aws_region.current.name}.ec2messages",
      type    = "Interface"
    },
    logs = {
      service = "com.amazonaws.${data.aws_region.current.name}.logs",
      type    = "Interface"
    },
    kms = {
      service = "com.amazonaws.${data.aws_region.current.name}.kms",
      type    = "Interface"
    },
    sts = {
      service = "com.amazonaws.${data.aws_region.current.name}.sts",
      type    = "Interface"
    },
    monitoring = {
      service = "com.amazonaws.${data.aws_region.current.name}.monitoring",
      type    = "Interface"
    }
  })
}

data "aws_vpc" "selected_vpc" {
  id = var.vpc_id
}

data "aws_subnets" "selected_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected_vpc.id]
  }
}

resource "aws_vpc_endpoint" "ssm_vpc_endpoints" {
  for_each = local.endpoints

  vpc_id              = var.vpc_id
  service_name        = each.value.service
  vpc_endpoint_type   = each.value.type
  subnet_ids          = each.value.type == "Interface" ? data.aws_subnets.selected_vpc_subnets.ids : null
  private_dns_enabled = each.value.type == "Interface" ? true : null

  tags = var.tags
}
