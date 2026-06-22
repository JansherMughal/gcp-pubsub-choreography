# ---------------------------------------------------------------------------
# The functions. Source for each is assembled by build.py into
# terraform/.build/src/<service> (service code + vendored shared lib). Run
# `python build.py` before `terraform apply` — see README.
#
#   orders-api        : public HTTP, Flask multi-route (place/accept/complete).
#                       The article's place-order / accept-order / complete-order
#                       functions, co-located as one bounded-context "orders API".
#   notify-restaurant : internal, push-triggered by order_placed.
#   notify-user       : internal, push-triggered by order_accepted.
# ---------------------------------------------------------------------------

module "fn_orders_api" {
  source                = "./modules/cloud_function"
  project_id            = var.project_id
  region                = var.region
  runtime               = var.runtime
  name                  = "orders-api"
  entry_point           = "orders_api"
  source_dir            = "${path.root}/.build/src/orders_api"
  source_bucket         = google_storage_bucket.function_sources.name
  service_account_email = google_service_account.orders_api.email
  labels                = local.labels
  ingress_settings      = "ALLOW_ALL" # public-facing orders API

  environment_variables = {
    GCP_PROJECT           = var.project_id
    TOPIC_ORDER_PLACED    = module.topic_order_placed.name
    TOPIC_ORDER_ACCEPTED  = module.topic_order_accepted.name
    TOPIC_ORDER_COMPLETED = module.topic_order_completed.name
    EVENT_SOURCE          = "orders-api"
  }

  depends_on = [google_project_service.enabled]
}

module "fn_notify_restaurant" {
  source                = "./modules/cloud_function"
  project_id            = var.project_id
  region                = var.region
  runtime               = var.runtime
  name                  = "notify-restaurant"
  entry_point           = "handle_push"
  source_dir            = "${path.root}/.build/src/notify_restaurant"
  source_bucket         = google_storage_bucket.function_sources.name
  service_account_email = google_service_account.notify_restaurant.email
  labels                = local.labels
  ingress_settings      = "ALLOW_INTERNAL_ONLY"

  environment_variables = {
    GCP_PROJECT               = var.project_id
    TOPIC_RESTAURANT_NOTIFIED = module.topic_restaurant_notified.name
    EVENT_SOURCE              = "notify-restaurant"
  }

  depends_on = [google_project_service.enabled]
}

module "fn_notify_user" {
  source                = "./modules/cloud_function"
  project_id            = var.project_id
  region                = var.region
  runtime               = var.runtime
  name                  = "notify-user"
  entry_point           = "handle_push"
  source_dir            = "${path.root}/.build/src/notify_user"
  source_bucket         = google_storage_bucket.function_sources.name
  service_account_email = google_service_account.notify_user.email
  labels                = local.labels
  ingress_settings      = "ALLOW_INTERNAL_ONLY"

  environment_variables = {
    GCP_PROJECT         = var.project_id
    TOPIC_USER_NOTIFIED = module.topic_user_notified.name
    EVENT_SOURCE        = "notify-user"
  }

  depends_on = [google_project_service.enabled]
}
