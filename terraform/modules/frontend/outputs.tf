output "bucket_name" {
  description = "Cloud Storage bucket name (for gsutil uploads)."
  value       = google_storage_bucket.frontend.name
}

output "bucket_url" {
  description = "Cloud Storage bucket public URL (gs://...)."
  value       = "gs://${google_storage_bucket.frontend.name}"
}

output "frontend_url" {
  description = "Public HTTPS URL to access index.html."
  value       = "https://storage.googleapis.com/${google_storage_bucket.frontend.name}"
}
