# ---------------------------------------------------------------------------
# Per-function service accounts + least-privilege grants.
#
# Each function publishes ONLY to the topics it owns (enforced at the IAM
# layer, per council point #1). No function may publish to a topic it doesn't
# emit, which keeps the event contracts honest.
# ---------------------------------------------------------------------------

resource "google_service_account" "orders_api" {
  project      = var.project_id
  account_id   = "orders-api-sa"
  display_name = "orders-api runtime"
}

resource "google_service_account" "notify_restaurant" {
  project      = var.project_id
  account_id   = "notify-restaurant-sa"
  display_name = "notify-restaurant runtime"
}

resource "google_service_account" "notify_user" {
  project      = var.project_id
  account_id   = "notify-user-sa"
  display_name = "notify-user runtime"
}

# Dedicated identity Pub/Sub uses to authenticate push requests to the notifier
# functions. Separate from the runtime SAs so "who may invoke" and "what the
# code may do" are independent.
resource "google_service_account" "pubsub_push" {
  project      = var.project_id
  account_id   = "pubsub-push-sa"
  display_name = "Pub/Sub push invoker"
}

# --- Publisher grants (one function -> only its own topics) ------------------
resource "google_pubsub_topic_iam_member" "orders_api_publishes" {
  for_each = {
    order_placed    = module.topic_order_placed.id
    order_accepted  = module.topic_order_accepted.id
    order_completed = module.topic_order_completed.id
  }
  project = var.project_id
  topic   = each.value
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.orders_api.email}"
}

resource "google_pubsub_topic_iam_member" "notify_restaurant_publishes" {
  project = var.project_id
  topic   = module.topic_restaurant_notified.id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.notify_restaurant.email}"
}

resource "google_pubsub_topic_iam_member" "notify_user_publishes" {
  project = var.project_id
  topic   = module.topic_user_notified.id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.notify_user.email}"
}

# --- Firestore access (all functions read/write order + idempotency state) ---
resource "google_project_iam_member" "firestore_users" {
  for_each = toset([
    google_service_account.orders_api.email,
    google_service_account.notify_restaurant.email,
    google_service_account.notify_user.email,
  ])
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${each.value}"
}

# --- Push invoker: Pub/Sub may invoke the two notifier functions -------------
resource "google_cloud_run_v2_service_iam_member" "orders_api_public" {
  project  = var.project_id
  location = var.region
  name     = module.fn_orders_api.run_service_name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "push_invoke_notify_restaurant" {
  project  = var.project_id
  location = var.region
  name     = module.fn_notify_restaurant.run_service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_push.email}"
}

resource "google_cloud_run_v2_service_iam_member" "push_invoke_notify_user" {
  project  = var.project_id
  location = var.region
  name     = module.fn_notify_user.run_service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_push.email}"
}

# --- Artifact Registry access: Compute Engine default SA can access build artifacts -----
data "google_project" "project" {
  project_id = var.project_id
}

resource "null_resource" "cloudfunctions_artifact_reader" {
  triggers = {
    project = var.project_id
    project_number = data.google_project.project.number
  }

  provisioner "local-exec" {
    command = "gcloud projects add-iam-policy-binding ${var.project_id} --member=serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com --role=roles/artifactregistry.reader --quiet"
  }

  depends_on = [google_project_service.enabled]
}
