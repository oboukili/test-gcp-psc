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

resource "random_password" "postgres" {
  length      = 50
  special     = false
  min_numeric = 5
  min_lower   = 5
  min_upper   = 5
}

resource "google_sql_user" "users" {
  name     = "poc"
  instance = google_sql_database_instance.postgres.name
  password = random_password.postgres.result
}