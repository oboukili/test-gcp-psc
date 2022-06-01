resource "google_project_service" "apis" {
  for_each = toset([
    "dns.googleapis.com",
    "servicenetworking.googleapis.com",
  ])
  service = each.value

  disable_dependent_services = true

  timeouts {
    create = "30m"
    update = "40m"
  }
}