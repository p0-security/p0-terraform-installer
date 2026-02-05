resource "random_id" "name" {
  keepers = {
    "cluster_name" = var.cluster_name
  }
  byte_length = 2
}

locals {
  cluster_name = replace(lower("${var.cluster_name}-docdb-${random_id.name.hex}"), "/[^a-z0-9-]/", "")
}
