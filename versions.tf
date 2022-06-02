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
    time = {
      source  = "hashicorp/time"
      version = "~> 0"
    }
  }
}

locals {
  consumer_project = "olivierboukili-playground2"
  producer_project = "olivierboukili-playground1"
}

provider "google" {
  region  = "europe-west1"
  zone    = "europe-west1-b"
  project = local.producer_project
}