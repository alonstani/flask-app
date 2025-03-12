provider "google" {
  credentials = file(var.gcp_credentials_path)  # Should point to /tmp/gcp_credentials.json
  project     = var.gcp_project_id
  region      = var.gke_cluster_region
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
  name     = "my-cluster"
  location = var.gke_cluster_region

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
