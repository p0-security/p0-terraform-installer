terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = ">= 4.8.0"
    }
    p0 = {
      source  = "p0-security/p0"
      version = "0.24.0"
    }
  }
}
