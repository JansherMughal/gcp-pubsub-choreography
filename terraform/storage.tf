# Bucket holding zipped function sources. Versioned so a bad deploy can be rolled
# back to a previous source object.
resource "random_id" "suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "function_sources" {
  name     = "${var.project_id}-fn-sources-${random_id.suffix.hex}"
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }

  # Function source zips are disposable build artifacts — expire old versions
  # to avoid unbounded storage growth (and cost).
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.enabled]
}
