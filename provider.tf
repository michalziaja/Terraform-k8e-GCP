terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.74.0"
    }
  }
}
provider "google" {
    credentials = "./key.json"
    project = "rational-autumn-393513"
    region = "us-west1"
    }
