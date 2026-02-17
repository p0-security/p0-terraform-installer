terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.16.0"
    }
    p0 = {
      source  = "p0-security/p0"
      version = ">= 0.24.0"
    }
  }
}