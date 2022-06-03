resource "google_compute_address" "psc_ilb_consumer_address" {
  name         = "psc-ilb-consumer"
  subnetwork   = "default"
  address_type = "INTERNAL"
  project      = local.consumer_project
}

resource "google_compute_forwarding_rule" "psc_ilb_consumer" {
  name                  = "psc-ilb-consumer"
  target                = google_compute_service_attachment.psc_proxy.id
  load_balancing_scheme = "" # need to override EXTERNAL default when target is a service attachment
  network               = "default"
  ip_address            = google_compute_address.psc_ilb_consumer_address.id
  project               = local.consumer_project
}
