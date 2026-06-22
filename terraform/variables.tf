variable "project_id" {
  description = "GCP project ID to deploy into."
  type        = string
}

variable "region" {
  description = "Region for functions, Pub/Sub, and Firestore."
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod). Used in labels and names."
  type        = string
  default     = "dev"
}

variable "runtime" {
  description = "Python runtime for all functions."
  type        = string
  default     = "python312"
}

variable "sendgrid_api_key" {
  description = "SendGrid API key for sending confirmation emails."
  type        = string
  sensitive   = true
  default     = ""
}

# --- Cost / ownership labels -------------------------------------------------
# The Infracost FinOps subcommands (policies/budgets) were unavailable in this
# environment (base CLI only), so we apply conventional GCP labels for cost
# attribution rather than an org-mandated tagging scheme. Adjust to taste.
variable "team" {
  description = "Owning team label."
  type        = string
  default     = "order-platform"
}

variable "cost_center" {
  description = "Cost center label."
  type        = string
  default     = "engineering"
}

locals {
  labels = {
    app         = "food-ordering"
    pattern     = "choreography"
    environment = var.environment
    team        = var.team
    cost_center = var.cost_center
    managed_by  = "terraform"
  }
}
