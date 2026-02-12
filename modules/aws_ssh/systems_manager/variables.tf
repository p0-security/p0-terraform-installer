variable "regional_aws" {
  type = map(object({
    enabled_vpcs = set(string)
  }))
}
