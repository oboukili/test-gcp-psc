resource "google_sql_database_instance" "postgres" {
  name             = "psc-test"
  database_version = "POSTGRES_13"
  region           = "europe-west1"

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.psc.id
    }
  }
  depends_on = [google_service_networking_connection.service_networking]
}
