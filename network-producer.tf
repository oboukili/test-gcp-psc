resource "google_compute_network" "psc" {
  name                    = "psc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "psc_ilb_producer_subnetwork" {
  name                     = "psc-ilb-producer-subnetwork"
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

resource "google_compute_global_address" "service_networking" {
  name          = "service-networking"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.psc.id
}

resource "google_service_networking_connection" "service_networking" {
  network                 = google_compute_network.psc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.service_networking.name]
  depends_on              = [google_project_service.apis]
}

resource "google_compute_health_check" "postgresql" {
  name               = "postgresql"
  check_interval_sec = 5
  timeout_sec        = 4
  log_config {
    enable = true
  }
  tcp_health_check {
    port = "5432"
  }
}

data "google_netblock_ip_ranges" "healthchecks" {
  for_each = toset([
    "health-checkers",
    "legacy-health-checkers",
  ])
  range_type = each.value
}

resource "google_compute_firewall" "postgresql" {
  name    = "postgresql"
  network = google_compute_network.psc.name
  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }
  source_ranges = setunion(
    flatten([for r in data.google_netblock_ip_ranges.healthchecks : r.cidr_blocks_ipv4]),
    # WARN: Note that the following is essential to allow traffic from the PSC SNAT IP ranges (e.g. all consumers) to connect to the proxy
    toset([google_compute_subnetwork.psc_ilb_nat.ip_cidr_range])
  )
  target_tags = ["proxy"]
}

resource "google_compute_region_backend_service" "proxy_tcp" {
  name             = "proxy-tcp"
  session_affinity = "CLIENT_IP_PORT_PROTO"
  health_checks = [
    google_compute_health_check.postgresql.id,
  ]
  backend {
    group = google_compute_region_instance_group_manager.proxy.instance_group
  }
}

resource "google_compute_forwarding_rule" "psc_proxy" {
  name                  = "psc-proxy"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.proxy_tcp.id
  allow_global_access   = true
  all_ports             = false
  ports                 = ["5432"]
  network               = google_compute_subnetwork.psc_ilb_producer_subnetwork.network
  subnetwork            = google_compute_subnetwork.psc_ilb_producer_subnetwork.name
}

resource "google_compute_service_attachment" "psc_proxy" {
  name                  = "psc-proxy"
  enable_proxy_protocol = false
  connection_preference = "ACCEPT_MANUAL"
  nat_subnets           = [google_compute_subnetwork.psc_ilb_nat.id]
  target_service        = google_compute_forwarding_rule.psc_proxy.id

  consumer_accept_lists {
    project_id_or_num = local.consumer_project
    connection_limit  = 10
  }
}