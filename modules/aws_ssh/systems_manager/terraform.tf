terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.42.0"
      configuration_aliases = [
        aws.default,
        aws.us_west_1,
        aws.us_west_2,
      ]
    }
  }
}
