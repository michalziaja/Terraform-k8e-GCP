provider "google" {
    credentials = file(var.gcp_credentials)
    project = var.gcp_project_id
    region = var.region
    }
    
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.74.0"
    }
  }
}
