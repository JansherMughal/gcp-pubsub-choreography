# ---------------------------------------------------------------------------
# The five domain events, one Pub/Sub topic each.
#
#   order_placed        -> emitted by orders-api  (place)    -> notify-restaurant
#   restaurant_notified -> emitted by notify-restaurant      -> (other contexts)
#   order_accepted      -> emitted by orders-api  (accept)   -> notify-user
#   user_notified       -> emitted by notify-user            -> (other contexts)
#   order_completed     -> emitted by orders-api  (complete) -> (promo, data-lake)
#
# restaurant_notified / user_notified / order_completed have no internal
# consumer here — that is the point of choreography: other bounded contexts can
# subscribe later (a promo-code service on order_completed, a BI sink on all of
# them) without this stack ever knowing.
# ---------------------------------------------------------------------------
module "topic_order_placed" {
  source     = "./modules/pubsub_topic"
  project_id = var.project_id
  name       = "order-placed"
  labels     = local.labels
}

module "topic_restaurant_notified" {
  source     = "./modules/pubsub_topic"
  project_id = var.project_id
  name       = "restaurant-notified"
  labels     = local.labels
}

module "topic_order_accepted" {
  source     = "./modules/pubsub_topic"
  project_id = var.project_id
  name       = "order-accepted"
  labels     = local.labels
}

module "topic_user_notified" {
  source     = "./modules/pubsub_topic"
  project_id = var.project_id
  name       = "user-notified"
  labels     = local.labels
}

module "topic_order_completed" {
  source     = "./modules/pubsub_topic"
  project_id = var.project_id
  name       = "order-completed"
  labels     = local.labels
}
