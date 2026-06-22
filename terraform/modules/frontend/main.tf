# ---------------------------------------------------------------------------
# frontend (GCP)
#
# Minimal static file hosting: Cloud Storage bucket with CORS for API proxying.
# Upload ui/ files via gsutil; served directly from Cloud Storage.
# ---------------------------------------------------------------------------

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "frontend" {
  name                        = "${var.name_prefix}-frontend-${random_id.bucket_suffix.hex}"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"
  labels                      = var.tags

  # Website serving: index.html for root, not 404 error pages (SPA support).
  website {
    main_page_suffix = "index.html"
    # Not_found_page is intentionally omitted — we let 404s return index.html
    # for SPA routing via JavaScript.
  }

  # CORS: allow the frontend to call the API backend via fetch/XMLHttpRequest.
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  # Versioning for rollback capability.
  versioning {
    enabled = true
  }

  # Lifecycle: keep the 10 most recent object versions, delete old ones after 30 days.
  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Make the bucket publicly readable (so browsers can fetch assets).
resource "google_storage_bucket_iam_member" "frontend_public_read" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

