output "subscription_id" {
  description = "Fully-qualified subscription id."
  value       = google_pubsub_subscription.this.id
}

output "dead_letter_topic_id" {
  description = "Fully-qualified DLQ topic id."
  value       = google_pubsub_topic.dead_letter.id
}
