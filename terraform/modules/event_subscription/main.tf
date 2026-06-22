# ---------------------------------------------------------------------------
# event_subscription
#
# Wires one consumer (a Cloud Function) to one event topic via an explicit
# Pub/Sub *push* subscription. We manage the subscription ourselves (rather than
# letting a gen2 event-trigger auto-create it) precisely so we can configure the
# three things the council called non-negotiable for this pattern:
#
#   * dead-letter topic  -> "poison pill" events are parked, never silently lost
#   * retry policy        -> exponential backoff on transient handler failures
#   * message ordering    -> per-order_completed-after-order_accepted guarantees
#
# Push (not pull) so the consumer stays a stateless, scale-to-zero function.
# ---------------------------------------------------------------------------

# Dead-letter topic: each subscription owns its own DLQ so failures are
# attributable to a specific consumer, not pooled into one ambiguous bucket.
resource "google_pubsub_topic" "dead_letter" {
  name    = "${var.name}-dlq"
  project = var.project_id
  labels  = var.labels
}

# A pull subscription on the DLQ keeps dead-lettered events durable and
# inspectable. Alert on this subscription's backlog in production.
resource "google_pubsub_subscription" "dead_letter" {
  name                       = "${var.name}-dlq-sub"
  project                    = var.project_id
  topic                      = google_pubsub_topic.dead_letter.id
  labels                     = var.labels
  message_retention_duration = "604800s" # 7d — give humans time to triage/replay
  expiration_policy {
    ttl = "" # never expire the DLQ sub
  }
}

resource "google_pubsub_subscription" "this" {
  name    = var.name
  project = var.project_id
  topic   = var.topic_id
  labels  = var.labels

  ack_deadline_seconds = var.ack_deadline_seconds

  # Deliver as an authenticated HTTPS push to the function's URL. The OIDC token
  # lets the underlying Cloud Run service verify the caller (roles/run.invoker
  # is granted to push_sa_email in the root module).
  push_config {
    push_endpoint = var.push_endpoint
    oidc_token {
      service_account_email = var.push_sa_email
    }
    # Ask Pub/Sub to wrap the payload in the standard push envelope so handlers
    # have a single, stable shape to parse regardless of producer.
    attributes = {
      "x-goog-version" = "v1"
    }
  }

  # At-least-once delivery means handlers MUST be idempotent (see shared/
  # idempotency.py). Retry transient failures with backoff before dead-lettering.
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  # Ordering keys (set to order_id by publishers) keep per-order events in
  # sequence so a consumer never sees order_completed before order_accepted.
  enable_message_ordering = var.enable_message_ordering

  expiration_policy {
    ttl = "" # never auto-delete the subscription
  }
}
