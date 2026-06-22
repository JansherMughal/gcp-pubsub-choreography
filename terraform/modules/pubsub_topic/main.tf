# ---------------------------------------------------------------------------
# pubsub_topic
#
# A single domain event in the choreography. The topic *name* is the contract:
# publishers emit to it without knowing who listens; subscribers listen without
# knowing who published. (Per council: this is what makes topic-per-event the
# correct shape for choreography rather than a single shared "ESB" topic.)
# ---------------------------------------------------------------------------

resource "google_pubsub_topic" "this" {
  name    = var.name
  project = var.project_id
  labels  = var.labels

  # Retain published events so a late-subscribing bounded context (e.g. a
  # promo-code service reacting to order_completed) or a data-lake sink can
  # replay history rather than only seeing events from its creation onward.
  message_retention_duration = var.message_retention_duration
}
