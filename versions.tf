terraform {
  required_version = "~> 1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4"
    }
  }
}

provider "google" {
  region  = "europe-west1"
  project = "olivierboukili-playground1"
}