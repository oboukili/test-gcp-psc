resource "google_compute_network" "psc" {
  name                    = "psc"
  auto_create_subnetworks = false
}

resource "google_compute_global_address" "service_networking" {
  name          = "service-networking"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.psc.id
}

resource "google_compute_subnetwork" "psc_ilb_producer_network" {
  name                     = "psc-ilb-producer-network"
  network                  = google_compute_network.psc.id
  ip_cidr_range            = "10.0.0.0/16"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "psc_ilb_nat" {
  name          = "psc-ilb-nat"
  network       = google_compute_network.psc.id
  purpose       = "PRIVATE_SERVICE_CONNECT"
  ip_cidr_range = "10.1.0.0/16"
}

resource "google_service_networking_connection" "service_networking" {
  network                 = google_compute_network.psc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.service_networking.name]
  depends_on              = [google_project_service.apis]
}

## Optional, just for the sake of the PoC to install some simple TCP Proxy over the public packages
## Use a golden image template instead created with Hashicorp Packer for example.

resource "google_compute_router" "nat_gateway" {
  name    = "nat-gateway"
  network = google_compute_network.psc.name
}

resource "google_compute_address" "nat_gateway" {
  count = 2
  name  = format("nat-gateway-%s", count.index + 1)
}

resource "google_compute_router_nat" "nat_gateway" {
  name   = "nat-gateway"
  router = google_compute_router.nat_gateway.name
  region = google_compute_router.nat_gateway.region

  nat_ip_allocate_option              = "MANUAL_ONLY"
  nat_ips                             = google_compute_address.nat_gateway.*.self_link
  enable_endpoint_independent_mapping = true
  min_ports_per_vm                    = 4096

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.psc_ilb_producer_network.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
