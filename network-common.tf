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
  name          = "psc-ilb-producer-network"
  network       = google_compute_network.psc.id
  ip_cidr_range = "10.0.0.0/16"
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
}