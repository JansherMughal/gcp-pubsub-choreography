# For dead-lettering to work, the Pub/Sub service agent must be able to publish
# to the DLQ topic and acknowledge messages on the source subscription.
# https://cloud.google.com/pubsub/docs/handling-failures#dead_letter_topic

data "google_project" "this" {
  project_id = var.project_id
}

locals {
  pubsub_sa = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.dead_letter.id
  role    = "roles/pubsub.publisher"
  member  = local.pubsub_sa
}

resource "google_pubsub_subscription_iam_member" "source_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.this.id
  role         = "roles/pubsub.subscriber"
  member       = local.pubsub_sa
}
