resource "google_compute_health_check" "postgresql" {
  name               = "postgresql"
  check_interval_sec = 10
  timeout_sec        = 5
  tcp_health_check {
    port = "5432"
  }
}

resource "google_compute_health_check" "envoy" {
  name               = "envoy"
  check_interval_sec = 10
  timeout_sec        = 5
  tcp_health_check {
    port = "15001"
  }
}

resource "google_compute_region_backend_service" "proxy_tcp" {
  name             = "proxy-tcp"
  session_affinity = "CLIENT_IP_PORT_PROTO"
  health_checks = [
    google_compute_health_check.envoy.id,
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
  network               = google_compute_subnetwork.psc_ilb_producer_network.network
  subnetwork            = google_compute_subnetwork.psc_ilb_producer_network.name
}

resource "google_compute_service_attachment" "psc_proxy" {
  name                  = "psc-proxy"
  enable_proxy_protocol = true
  connection_preference = "ACCEPT_MANUAL"
  nat_subnets           = [google_compute_subnetwork.psc_ilb_nat.id]
  target_service        = google_compute_forwarding_rule.psc_proxy.id

  consumer_accept_lists {
    project_id_or_num = "olivierboukili-playground2"
    connection_limit  = 10
  }
}