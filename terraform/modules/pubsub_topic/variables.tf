variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "name" {
  description = "Topic name, e.g. order-placed. Doubles as the event contract."
  type        = string
}

variable "labels" {
  description = "Labels applied to the topic (cost attribution / ownership)."
  type        = map(string)
  default     = {}
}

variable "message_retention_duration" {
  description = "How long Pub/Sub retains published messages on the topic."
  type        = string
  default     = "86400s" # 24h
}
