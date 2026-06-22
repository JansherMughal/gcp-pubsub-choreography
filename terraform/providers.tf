provider "google" {
  project = var.project_id
  region  = var.region

  # Apply the same ownership/cost labels to every resource that supports them,
  # so spend is attributable even where we don't set labels explicitly.
  default_labels = local.labels
}
