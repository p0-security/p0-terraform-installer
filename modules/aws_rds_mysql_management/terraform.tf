terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    p0 = {
      source  = "p0-security/p0"
      version = "0.32.0"
    }
  }
}
