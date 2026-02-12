module "aws_vpc_endpoint" {
  for_each = var.enabled_vpcs

  source = "./modules/vpc_endpoints"

  vpc_id = each.key
  tags   = local.tags
}
