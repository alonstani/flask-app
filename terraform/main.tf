provider "google" {
  credentials = file("path_to_your_credentials_file.json")  # Provide the correct path to your credentials file
  project     = "inyoukproject"  # Project ID is hardcoded
  region      = "us-west1-b"    # Region is hardcoded
}

resource "google_container_cluster" "primary" {
  name     = "my-cluster"   # Cluster name is hardcoded
  location = "us-west1-b"   # Region is hardcoded

  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "node-pool"
  location   = "us-west1-b"  # Region is hardcoded
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    machine_type = "e2-standard-2"
    disk_type    = "pd-standard"
  }
}
