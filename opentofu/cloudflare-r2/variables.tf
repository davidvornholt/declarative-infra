variable "account_id" {
  description = "Cloudflare account that owns the R2 buckets."
  type        = string
}

variable "buckets" {
  description = "R2 buckets to manage, keyed by a stable identifier."
  type = map(object({
    name          = string
    jurisdiction  = optional(string)
    location      = optional(string)
    storage_class = optional(string, "Standard")
  }))
}
