## Optional, just for the sake of the PoC to install some simple TCP Proxy over the public packages on the producer proxy
## Use a golden image template instead created with Hashicorp Packer for example.

# Producer network

resource "google_compute_router" "nat_gateway_producer" {
  name    = "nat-gateway"
  network = google_compute_network.psc.name
}

resource "google_compute_address" "nat_gateway_producer" {
  count = 2
  name  = format("nat-gateway-%s", count.index + 1)
}

resource "google_compute_router_nat" "nat_gateway_producer" {
  name   = "nat-gateway"
  router = google_compute_router.nat_gateway_producer.name
  region = google_compute_router.nat_gateway_producer.region

  nat_ip_allocate_option              = "MANUAL_ONLY"
  nat_ips                             = google_compute_address.nat_gateway_producer.*.self_link
  enable_endpoint_independent_mapping = true
  min_ports_per_vm                    = 4096

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.psc_ilb_producer_subnetwork.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Consumer network

resource "google_compute_router" "nat_gateway_consumer" {
  name    = "nat-gateway"
  network = "default"
  project = local.consumer_project
}

resource "google_compute_address" "nat_gateway_consumer" {
  count   = 2
  name    = format("nat-gateway-%s", count.index + 1)
  project = local.consumer_project
}

resource "google_compute_router_nat" "nat_gateway_consumer" {
  name    = "nat-gateway"
  router  = google_compute_router.nat_gateway_consumer.name
  region  = google_compute_router.nat_gateway_consumer.region
  project = local.consumer_project

  nat_ip_allocate_option              = "MANUAL_ONLY"
  nat_ips                             = google_compute_address.nat_gateway_consumer.*.self_link
  enable_endpoint_independent_mapping = true
  min_ports_per_vm                    = 4096

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = "default"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
