variable "zone_id" {
  description = "Cloudflare zone that owns the records."
  type        = string
}

variable "records" {
  description = "DNS records to manage, keyed by a stable identifier."
  type = map(object({
    name     = string
    type     = string
    content  = optional(string)
    ttl      = optional(number, 1)
    proxied  = optional(bool, false)
    priority = optional(number)
    data = optional(object({
      port     = optional(number)
      priority = optional(number)
      target   = optional(string)
      weight   = optional(number)
    }))
  }))
}
