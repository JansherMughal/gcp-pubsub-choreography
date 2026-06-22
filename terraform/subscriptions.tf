# ---------------------------------------------------------------------------
# The two internal event wirings of the choreography. Each is a push
# subscription with its own DLQ, retry policy, and ordering — see the
# event_subscription module.
#
#   order_placed   --> notify-restaurant
#   order_accepted --> notify-user
#
# Note there is no subscription that "drives the next step" centrally. The flow
# advances only because each function, on completing its own job, emits the next
# event. That emergent chain *is* the choreography.
# ---------------------------------------------------------------------------

module "sub_notify_restaurant" {
  source        = "./modules/event_subscription"
  project_id    = var.project_id
  name          = "notify-restaurant-on-order-placed"
  topic_id      = module.topic_order_placed.id
  push_endpoint = module.fn_notify_restaurant.uri
  push_sa_email = google_service_account.pubsub_push.email
  labels        = local.labels

  depends_on = [
    google_cloud_run_v2_service_iam_member.push_invoke_notify_restaurant,
  ]
}

module "sub_notify_user" {
  source        = "./modules/event_subscription"
  project_id    = var.project_id
  name          = "notify-user-on-order-accepted"
  topic_id      = module.topic_order_accepted.id
  push_endpoint = module.fn_notify_user.uri
  push_sa_email = google_service_account.pubsub_push.email
  labels        = local.labels

  depends_on = [
    google_cloud_run_v2_service_iam_member.push_invoke_notify_user,
  ]
}
