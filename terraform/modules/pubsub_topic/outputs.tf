output "id" {
  description = "Fully-qualified topic id (projects/<p>/topics/<name>)."
  value       = google_pubsub_topic.this.id
}

output "name" {
  description = "Short topic name."
  value       = google_pubsub_topic.this.name
}
