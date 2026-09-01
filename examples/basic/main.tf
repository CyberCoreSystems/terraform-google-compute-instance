terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0, < 8.0"
    }
  }
}

provider "google" {
  project = "iacbazaar-example-project"
  region  = "us-central1"
  zone    = "us-central1-a"
}

module "vm" {
  source = "../../"

  project_id = "iacbazaar-example-project"
  name       = "example-app"
  zone       = "us-central1-a"

  # Private by default — no external IP. Use a real subnetwork in your project.
  subnetwork = "projects/iacbazaar-example-project/regions/us-central1/subnetworks/default"

  tags = ["app"]

  labels = {
    environment = "example"
    managed_by  = "iac-bazaar"
  }
}

output "instance_id" {
  value = module.vm.id
}

output "internal_ip" {
  value = module.vm.internal_ip
}
