data "google_compute_default_service_account" "default" {
}

data "google_compute_image" "debian" {
  family  = "debian-9"
  project = "debian-cloud"
}

# https://cloud.google.com/traffic-director/docs/set-up-gce-vms-auto
resource "google_compute_instance_template" "envoy" {
  name           = "envoy"
  machine_type   = "e2-medium"
  can_ip_forward = true

  disk {
    source_image = data.google_compute_image.debian.self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_subnetwork.psc_ilb_producer_network.network
    subnetwork = google_compute_subnetwork.psc_ilb_producer_network.name
  }

  scheduling {
    preemptible       = false
    automatic_restart = true
  }

  metadata = {
    gce-software-declaration = <<-EOF
    {
      "softwareRecipes": [{
        "name": "install-gce-service-proxy-agent",
        "desired_state": "INSTALLED",
        "installSteps": [{
          "scriptRun": {
            "script": "#! /bin/bash\nZONE=$(curl --silent http://metadata.google.internal/computeMetadata/v1/instance/zone -H Metadata-Flavor:Google | cut -d/ -f4 )\nexport SERVICE_PROXY_AGENT_DIRECTORY=$(mktemp -d)\nsudo gsutil cp   gs://gce-service-proxy-"$ZONE"/service-proxy-agent/releases/service-proxy-agent-0.2.tgz   "$SERVICE_PROXY_AGENT_DIRECTORY"   || sudo gsutil cp     gs://gce-service-proxy/service-proxy-agent/releases/service-proxy-agent-0.2.tgz     "$SERVICE_PROXY_AGENT_DIRECTORY"\nsudo tar -xzf "$SERVICE_PROXY_AGENT_DIRECTORY"/service-proxy-agent-0.2.tgz -C "$SERVICE_PROXY_AGENT_DIRECTORY"\n"$SERVICE_PROXY_AGENT_DIRECTORY"/service-proxy-agent/service-proxy-agent-bootstrap.sh"
          }
        }]
      }]
    }
    EOF
    gce-service-proxy        = <<-EOF
    {
      "api-version": "0.2",
      "proxy-spec": {
        "proxy-port": 15001,
        "network": "psc",
        "tracing": "ON",
        "access-log": "/var/log/envoy/access.log"
      }
      "service": {
        "serving-ports": [5432, 3306]
      },
     "labels": {
       "app_name": "proxy",
       "app_version": "STABLE"
      }
    }
    EOF
    enable-guest-attributes  = "true"
    enable-osconfig          = "true"
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  labels = {
    gce-service-proxy = "on"
  }
}


resource "google_compute_region_instance_group_manager" "proxy" {
  name               = "proxy"
  base_instance_name = "proxy"
  version {
    instance_template = google_compute_instance_template.envoy.id
  }

  named_port {
    name = "postgresql"
    port = 5432
  }
  named_port {
    name = "mysql"
    port = 3306
  }

  # TODO: set envoy healthcheck here instead
  auto_healing_policies {
    health_check      = google_compute_health_check.postgresql.id
    initial_delay_sec = 300
  }
}