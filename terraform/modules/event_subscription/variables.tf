variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "name" {
  description = "Subscription name, e.g. notify-restaurant-on-order-placed."
  type        = string
}

variable "topic_id" {
  description = "Fully-qualified id of the source event topic to subscribe to."
  type        = string
}

variable "push_endpoint" {
  description = "HTTPS URL of the consuming Cloud Function (gen2 run service URL)."
  type        = string
}

variable "push_sa_email" {
  description = "Service account whose OIDC token authenticates the push request."
  type        = string
}

variable "labels" {
  description = "Labels applied to the subscription and its DLQ."
  type        = map(string)
  default     = {}
}

variable "ack_deadline_seconds" {
  description = "How long the handler has to ack before redelivery."
  type        = number
  default     = 60
}

variable "max_delivery_attempts" {
  description = "Deliveries attempted before an event is dead-lettered (5-100)."
  type        = number
  default     = 5
}

variable "enable_message_ordering" {
  description = "Deliver events sharing an ordering key (order_id) in sequence."
  type        = bool
  default     = true
}
