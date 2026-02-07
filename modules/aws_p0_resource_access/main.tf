# All resources required for resource-based access with P0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.42.0"
    }
  }
}

locals {
  tags = {
    managed-by = "terraform"
  }
}

resource "aws_resourceexplorer2_index" "resource_index" {
  type = var.is_resource_explorer_aggregator ? "AGGREGATOR" : "LOCAL"
  tags = local.tags
}

resource "aws_resourceexplorer2_view" "default_view" {
  count = var.is_resource_explorer_aggregator ? 1 : 0

  name = "all-resources-p0"

  default_view = true

  included_property {
    name = "tags"
  }

  tags = local.tags

  depends_on = [aws_resourceexplorer2_index.resource_index]
}
