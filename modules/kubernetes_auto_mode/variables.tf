variable "kubernetes" {
  type = object({
    cluster = object({
      id              = string
      arn             = string
      endpoint        = string
      cert_authority  = string
      region          = string
      auto_mode_enabled = bool
    })
  })
}

variable "p0_config" {
    type = object({
        host    = string
        org     = string
    })
}