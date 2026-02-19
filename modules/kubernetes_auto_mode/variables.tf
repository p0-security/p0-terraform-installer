variable "kubernetes" {
  type = object({
    cluster = object({
      id              = string
      arn             = string
      endpoint        = string
      cert_authority  = string
      region          = string
    })
  })
}

variable "p0_config" {
    type = object({
        host    = string
        org     = string
    })
}