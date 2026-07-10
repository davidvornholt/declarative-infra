resource "cloudflare_r2_bucket" "bucket" {
  for_each = var.buckets

  account_id    = var.account_id
  name          = each.value.name
  jurisdiction  = each.value.jurisdiction
  location      = each.value.location
  storage_class = each.value.storage_class

  lifecycle {
    prevent_destroy = true
  }
}
