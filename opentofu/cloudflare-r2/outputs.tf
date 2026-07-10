output "bucket_names" {
  description = "R2 bucket names keyed by the input bucket identifier."
  value       = { for key, bucket in cloudflare_r2_bucket.bucket : key => bucket.name }
}
