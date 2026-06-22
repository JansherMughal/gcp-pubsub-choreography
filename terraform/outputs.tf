output "orders_api_url" {
  description = "Public base URL of the orders API. POST orders here to start the flow."
  value       = module.fn_orders_api.uri
}

output "event_topics" {
  description = "The five domain-event topics other bounded contexts can subscribe to."
  value = {
    order_placed        = module.topic_order_placed.name
    restaurant_notified = module.topic_restaurant_notified.name
    order_accepted      = module.topic_order_accepted.name
    user_notified       = module.topic_user_notified.name
    order_completed     = module.topic_order_completed.name
  }
}

output "dead_letter_topics" {
  description = "DLQs to alert on — non-empty means events are failing all retries."
  value = {
    notify_restaurant = module.sub_notify_restaurant.dead_letter_topic_id
    notify_user       = module.sub_notify_user.dead_letter_topic_id
  }
}

output "source_bucket" {
  description = "Bucket holding zipped function sources."
  value       = google_storage_bucket.function_sources.name
}

output "frontend_bucket" {
  description = "Cloud Storage bucket for frontend assets (ui/ files). Upload via gsutil."
  value       = module.frontend.bucket_name
}

output "frontend_url" {
  description = "Public HTTPS URL to access the frontend (index.html, customer.html, restaurant.html)."
  value       = module.frontend.frontend_url
}
