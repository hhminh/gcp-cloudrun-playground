terraform {
  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "${var.tf_org}"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
       name = "${var.tf_workspace}"
    }
  }
}

provider "google" {
  project = "${var.gcp_project}"
}
provider "google-beta" {
  project = "${var.gcp_project}"
}
# Deploy image to Cloud Run
resource "google_cloud_run_service" "apollo_test" {
    # service.metadata.name: only lowercase, digits, and hyphens; must begin with letter, and may not end with hyphen; must be less than 64 characters
  name     = "apollo-test"
  location = "australia-southeast1"
  template {
    spec {
      containers {
        image = "${var.img_path}"
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}
# Create public access
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}
# Enable public access on Cloud Run service
resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.apollo_test.location
  project     = google_cloud_run_service.apollo_test.project
  service     = google_cloud_run_service.apollo_test.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
# Return service URL
output "url" {
  value = "${google_cloud_run_service.apollo_test.status[0].url}"
}
