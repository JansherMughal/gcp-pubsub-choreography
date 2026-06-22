variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Region to deploy the function (and its Cloud Run service)."
  type        = string
}

variable "name" {
  description = "Function name, e.g. orders-api / notify-restaurant."
  type        = string
}

variable "runtime" {
  description = "Functions runtime."
  type        = string
  default     = "python312"
}

variable "entry_point" {
  description = "Name of the handler in main.py."
  type        = string
}

variable "source_dir" {
  description = "Local directory containing main.py + requirements.txt (+ vendored shared lib)."
  type        = string
}

variable "source_bucket" {
  description = "GCS bucket that stores zipped function sources."
  type        = string
}

variable "service_account_email" {
  description = "Runtime identity for the function (least-privilege publisher)."
  type        = string
}

variable "environment_variables" {
  description = "Environment variables passed to the function."
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels for cost attribution / ownership."
  type        = map(string)
  default     = {}
}

variable "available_memory" {
  description = "Memory per instance."
  type        = string
  default     = "256Mi"
}

variable "timeout_seconds" {
  description = "Max request duration."
  type        = number
  default     = 60
}

variable "min_instance_count" {
  description = "Minimum warm instances. 0 = scale to zero (cheapest)."
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Upper bound on autoscaling."
  type        = number
  default     = 3
}

variable "ingress_settings" {
  description = "ALLOW_ALL (public API) or ALLOW_INTERNAL_ONLY (push-only notifiers)."
  type        = string
  default     = "ALLOW_INTERNAL_ONLY"
}
