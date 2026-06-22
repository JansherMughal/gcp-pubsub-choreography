output "name" {
  description = "Function name."
  value       = google_cloudfunctions2_function.this.name
}

output "uri" {
  description = "HTTPS URL of the function (its underlying Cloud Run service)."
  value       = google_cloudfunctions2_function.this.service_config[0].uri
}

output "run_service_name" {
  description = "Underlying Cloud Run service name (for IAM invoker bindings)."
  value       = google_cloudfunctions2_function.this.name
}
