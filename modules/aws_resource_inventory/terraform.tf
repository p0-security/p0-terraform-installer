terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.42.0"
      configuration_aliases = [
        aws,
        aws.us_west_1,
        aws.us_west_2,
      ]
    }
    p0 = {
      source  = "p0-security/p0"
      version = ">= 0.24.0"
    }
  }
}
