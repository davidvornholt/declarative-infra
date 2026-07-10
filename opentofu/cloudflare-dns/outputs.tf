output "record_ids" {
  description = "Cloudflare record ids keyed by the input record identifier."
  value       = { for key, record in cloudflare_dns_record.managed : key => record.id }
}
