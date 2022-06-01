resource "google_compute_instance_template" "consumer" {
  name         = "consumer"
  machine_type = "e2-medium"
  project      = "olivierboukili-playground2"

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
  project                  = "olivierboukili-playground2"
}