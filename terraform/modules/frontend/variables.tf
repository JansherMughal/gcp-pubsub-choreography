variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the Cloud Storage bucket."
  type        = string
  default     = "us-central1"
}

variable "name_prefix" {
  description = "Prefix for the bucket name (must be globally unique)."
  type        = string
}

variable "tags" {
  description = "Labels to apply to Cloud Storage bucket."
  type        = map(string)
  default     = {}
}
