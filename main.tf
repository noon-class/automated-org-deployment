terraform {

  # backend "remote" {
  #   hostname = "app.terraform.io"
  #   organization = "example-org-3b45be"

  #   workspaces {
  #     name = "accounts-api"
  #   }
  # }

  cloud {
    organization = "example-org-3b45be"

    workspaces {
      name = "accounts-api"
    }
  }

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

# data "terraform_remote_state" "dns" {
#   records = 
# }

provider "google" {
  # credentials = file("nc-sandbox-367217-941ac9e700e4.json")

  project = "nc-sandbox-367217"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_cloud_run_service" "default" {
  name     = "cloudrun-srv"
  location = "us-central1"

  template {
    spec {
      service_account_name = "perry-169@nc-sandbox-367217.iam.gserviceaccount.com"
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
        # startup_probe {
        #   tcp_socket {
        #     port = 80
        #   }
        # }
      }
    }
  }
}
resource "google_cloud_run_domain_mapping" "default" {
  location = "us-central1"
  name     = var.subdomain

  metadata {
    namespace = "nc-sandbox-367217"
  }

  spec {
    route_name = google_cloud_run_service.default.name
  }
  depends_on = [
    google_cloud_run_service.default
  ]
}

variable "subdomain" {
  default = "apple.nooncourse.com"
  type = string
}

# output "org_subdomain" {
#   value = var.subdomain
# }
# output "records" {
#   value = {for i, v in google_cloud_run_domain_mapping.default.status[0].resource_records : i => v }
# }


resource "google_dns_record_set" "default" {
  count = length(local.records_to_deploy)
  # for_each = local.records_to_deploy
  managed_zone = "nooncourse-com"
  name = "${var.subdomain}."
  ttl = 100
  # type = each.value["type"]
  # rrdatas = [ each.value["rrdata"] ]
  type = local.records_to_deploy[tostring(count.index)].type
  rrdatas = [local.records_to_deploy[tostring(count.index)].rrdata]
  depends_on = [
    google_cloud_run_domain_mapping.default
  ]
}

locals {
  records_to_deploy = {for i, v in google_cloud_run_domain_mapping.default.status[0].resource_records : i => v }
}