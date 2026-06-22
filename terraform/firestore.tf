# Firestore is the *system of record* for order state. Events on Pub/Sub are
# lightweight notifications ("order 123 was accepted"); the full order document
# lives here. This is the council's key decoupling rule: state in the database,
# not smuggled through events. The same database also backs idempotency
# (the `processed_events` collection) so at-least-once redelivery is safe.
resource "google_firestore_database" "default" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.enabled]
}
