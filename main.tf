# enable APIs
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}
resource "google_project_service" "container" {
  service = "container.googleapis.com"
}

# create main VPC
resource "google_compute_network" "main" {
  name = "main"
  routing_mode = "REGIONAL"
  auto_create_subnetworks = false
  mtu = 1460
  delete_default_routes_on_create = false

  depends_on = [ 
    google_project_service.compute,
    google_project_service.container
   ]
}

# create subnets
resource "google_compute_subnetwork" "private" {
  name = "private"
  ip_cidr_range = "10.0.0.0/18"
  network = google_compute_network.main.name
  region = "us-west1"
  private_ip_google_access = true

secondary_ip_range {
    range_name = "k8s-pod-range"
    ip_cidr_range = "10.48.0.0/14"
}
secondary_ip_range {
    range_name = "k8s-service-range"
    ip_cidr_range = "10.52.0.0/20"
}
}

# create router
resource "google_compute_router" "router" {
    name = "router"
    region = "us-west1"  
    network = google_compute_network.main.id
}

# create nat
resource "google_compute_router_nat" "nat" {
    name = "nat"
    region = "us-west1"
    router = google_compute_router.router.name

    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    nat_ip_allocate_option = "MANUAL_ONLY"

    subnetwork {
      name = google_compute_subnetwork.private.id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
    nat_ips = [ google_compute_address.nat.self_link ]
    }

resource "google_compute_address" "nat" {
    name = "nat"
    address_type = "EXTERNAL"
    network_tier = "STANDARD"

    depends_on = [ google_project_service.compute ]
  
}

# create firewall
resource "google_compute_firewall" "allow-ssh" {
    name = "allow-ssh"
    network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

#create kubernetes
resource "google_container_cluster" "primary" {
    name = "primary"
    location = "us-west1-a"
    remove_default_node_pool = true
    initial_node_count = 1
    network = google_compute_network.main.self_link
    subnetwork = google_compute_subnetwork.private.self_link
    networking_mode = "VPC_NATIVE"

    node_locations = [
        "us-west1-b"
    ]

    addons_config {
      http_load_balancing {
        disabled = true
      }

      horizontal_pod_autoscaling {
        disabled = false
      }
      }

      ip_allocation_policy {
        cluster_secondary_range_name = "k8s-pod-range"
        services_secondary_range_name = "k8s-service-range"
      }

      private_cluster_config {
        enable_private_nodes = true
        enable_private_endpoint = false
        master_ipv4_cidr_block = "172.16.0.0/28"
      }
    }
    
