# ---------------------------------------------------------------------------
# Frontend static hosting on Cloud Storage.
#
# The ui/ folder (customer.html, restaurant.html, css/, js/) is uploaded here
# via gsutil. Cloud Storage serves it publicly with CORS enabled so browsers
# can fetch /api/* endpoints via relative URLs (proxied to the orders-api).
# ---------------------------------------------------------------------------

module "frontend" {
  source      = "./modules/frontend"
  project_id  = var.project_id
  region      = var.region
  name_prefix = "food-ordering-${var.environment}"
  tags        = local.labels

  depends_on = [google_project_service.enabled]
}
