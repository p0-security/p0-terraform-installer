terraform {
  # This declaration is needed to silence a warning: "Reference to undefined provider"
  # when passing in an AWS provider to this module
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
