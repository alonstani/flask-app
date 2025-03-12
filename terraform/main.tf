provider "google" {
  credentials = jsondecode(var.gcp_credentials_json)  # Pass the content as JSON
  project     = var.gcp_project_id
  region      = var.gke_cluster_region
}
variable "gcp_credentials_json" {
  description = "GCP credentials in JSON format"
  type        = string
}
variable "gcp_project_id" {
  description = "gcp project id"
  type        = string
}

variable "gcp_credentials_path" {
  description = "gcp_credentials_path"
  type        = string
}
variable "gke_cluster_region" {
  description = "The region where the GKE cluster is located"
  type        = string
}

variable "gke_cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}


resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name         # Use the cluster name variable
  location = var.gke_cluster_region      # Use the region varia

  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "node-pool"
  location   = var.gke_cluster_region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    machine_type = "e2-standard-2" 
    disk_type = "pd-standard"
  }
}
