terraform {
  required_version = "~> 1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
}

provider "google" {
  region  = "europe-west1"
  zone    = "europe-west1-b"
  project = "olivierboukili-playground1"
}