# Enable the Google Cloud APIs this stack depends on. Kept in one place so the
# dependency surface of the architecture is explicit and reviewable.
locals {
  required_apis = [
    "cloudfunctions.googleapis.com",   # gen2 functions
    "run.googleapis.com",              # gen2 runs on Cloud Run
    "cloudbuild.googleapis.com",       # builds function source
    "pubsub.googleapis.com",           # the event bus
    "eventarc.googleapis.com",         # eventing control plane
    "firestore.googleapis.com",        # order state + idempotency store
    "artifactregistry.googleapis.com", # function build images
    "storage.googleapis.com",          # source zips
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(local.required_apis)

  project = var.project_id
  service = each.value

  # Don't tear down shared APIs if this stack is destroyed.
  disable_on_destroy = false
}
