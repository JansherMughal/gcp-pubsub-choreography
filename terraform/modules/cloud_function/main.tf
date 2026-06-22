# ---------------------------------------------------------------------------
# cloud_function
#
# A 2nd-gen Cloud Function deployed from a local source directory. Gen2 runs on
# Cloud Run under the hood, so each function is an autoscaling, scale-to-zero
# HTTPS service. We expose every function over HTTP and drive the event-driven
# ones with explicit Pub/Sub push subscriptions (see the event_subscription
# module) rather than auto-created triggers, to keep DLQ/retry/ordering in code.
# ---------------------------------------------------------------------------

# Zip the (already-assembled, shared-lib-included) source directory. The hash in
# the object name forces a redeploy whenever the source changes.
data "archive_file" "source" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.build/${var.name}.zip"
}

resource "google_storage_bucket_object" "source" {
  name   = "sources/${var.name}/${data.archive_file.source.output_md5}.zip"
  bucket = var.source_bucket
  source = data.archive_file.source.output_path
}

resource "google_cloudfunctions2_function" "this" {
  name     = var.name
  project  = var.project_id
  location = var.region
  labels   = var.labels

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point
    source {
      storage_source {
        bucket = var.source_bucket
        object = google_storage_bucket_object.source.name
      }
    }
  }

  service_config {
    available_memory      = var.available_memory
    timeout_seconds       = var.timeout_seconds
    min_instance_count    = var.min_instance_count
    max_instance_count    = var.max_instance_count
    service_account_email = var.service_account_email
    environment_variables = var.environment_variables

    # ALLOW_ALL only for the public orders-API; notifiers are INTERNAL so they
    # are reachable only by Pub/Sub push from inside the project/VPC boundary.
    ingress_settings = var.ingress_settings
  }
}
