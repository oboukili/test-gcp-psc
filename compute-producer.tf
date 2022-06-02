data "google_compute_default_service_account" "default" {}

data "google_compute_image" "debian" {
  family  = "debian-10"
  project = "debian-cloud"
}

resource "time_static" "template_update" {
  triggers = {
    version = data.google_compute_image.debian.image_id
  }
}

resource "google_compute_instance_template" "proxy" {
  name           = format("proxy-%s", time_static.template_update.triggers.version)
  machine_type   = "e2-medium"
  can_ip_forward = true

  disk {
    source_image = data.google_compute_image.debian.self_link
    auto_delete  = true
    boot         = true
  }

  tags = ["proxy"]

  network_interface {
    network    = google_compute_subnetwork.psc_ilb_producer_subnetwork.network
    subnetwork = google_compute_subnetwork.psc_ilb_producer_subnetwork.name
  }

  scheduling {
    preemptible       = false
    automatic_restart = true
  }

  metadata = {
    startup-script          = <<EOT
apt-get update &&
apt-get install -y simpleproxy &&
simpleproxy -d -L 5432 -R ${google_sql_database_instance.postgres.private_ip_address}:5432
EOT
    enable-guest-attributes = "true"
    enable-osconfig         = "true"
  }

  service_account {
    # Not a best practice, only to showcase the PoC
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "proxy" {
  name               = "proxy"
  base_instance_name = "proxy"
  version {
    instance_template = google_compute_instance_template.proxy.id
  }

  named_port {
    name = "postgresql"
    port = 5432
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.postgresql.id
    initial_delay_sec = 300
  }
}

resource "google_compute_region_autoscaler" "proxy" {
  name   = "proxy"
  target = google_compute_region_instance_group_manager.proxy.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60
    cpu_utilization {
      target            = 0.7
      predictive_method = "OPTIMIZE_AVAILABILITY"
    }
  }
}