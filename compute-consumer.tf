data "google_compute_default_service_account" "default_consumer" {
  project = local.consumer_project
}

resource "google_compute_instance_template" "consumer" {
  name         = "consumer"
  machine_type = "e2-medium"
  project      = local.consumer_project
  service_account {
    email  = data.google_compute_default_service_account.default_consumer.email
    scopes = []
  }

  disk {
    source_image = "debian-cloud/debian-10"
    auto_delete  = true
    disk_size_gb = 10
    boot         = true
  }

  network_interface {
    network = "default"
  }

  can_ip_forward = false
}

resource "google_compute_instance_from_template" "consumer" {
  name                     = "consumer"
  source_instance_template = google_compute_instance_template.consumer.id
  project                  = local.consumer_project
}