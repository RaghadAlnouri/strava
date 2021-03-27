provider "google" {
  project = var.project # see variables.tf
  region  = var.region  # see variables.tf
}


# Service account for the function
resource "google_service_account" "service_account" {
  account_id   = "strava-api-sa"
  display_name = "Strava Function Service Account"
}


#--- Permissions ---
# Bigquery permissions
# BQ Job Creator
resource "google_project_iam_binding" "bigquery_job_iam" {
  project = var.project
  role    = "roles/bigquery.jobUser"
  members  = [
    "serviceAccount:${google_service_account.service_account.email}"
    ]
}

# Data Editor Permissions
resource "google_project_iam_binding" "bigquery_iam" {
  project = var.project
  role    = "roles/bigquery.dataEditor"
  members  = [
    "serviceAccount:${google_service_account.service_account.email}"
    ]
}

# Secret Manager Read
resource "google_project_iam_binding" "secretmngr_iam" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  members  = [
    "serviceAccount:${google_service_account.service_account.email}"
    ]
}

# Cloud Scheduler Function Trigger IAM
resource "google_project_iam_binding" "function_iam" {
  project = var.project
  role    = "roles/cloudfunctions.invoker"
  members  = [
    "serviceAccount:${google_service_account.service_account.email}"
    ]
} 
#--- END OF PERMISSIONS ---

# Big Query
# dataset creation
resource "google_bigquery_dataset" "dataset-strava" {
  dataset_id                  = "strava"
  friendly_name               = "strava"
  description                 = "Strava Data"
  location                    = var.region
}

# table creation
resource "google_bigquery_table" "table-activities" {
  dataset_id = "strava"
  table_id = "activities"
}

# Secret Manager
# Client ID
resource "google_secret_manager_secret" "secret-clientid" {
  secret_id = "strava_clientid"

 replication {
    user_managed {
      replicas {
          location = var.region
        }
    }
  }
}

# Client Secret
resource "google_secret_manager_secret" "secret-clientsecret" {
  secret_id = "strava_clientsecret"

 replication {
    user_managed {
      replicas {
          location = var.region
        }
    }
  }
}

# Refresh Token
resource "google_secret_manager_secret" "secret-token" {
  secret_id = "strava_refreshtoken"

 replication {
    user_managed {
      replicas {
          location = var.region
        }
    }
  }
}

# Cloud Scheduler
resource "google_cloud_scheduler_job" "strava-job" {
  name        = "Strava_api_trigger"
  description = "Job to trigger Strava API Cloud Function"
  schedule    = "0 */6 * * *" # every 6 hours.
  time_zone   = "America/New_York"
  retry_config {
    retry_count = 0
  }
  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${var.project}.cloudfunctions.net/strava-api"
    body        = base64encode("{}")
    oidc_token {
      service_account_email = google_service_account.service_account.email
    }
  }
}

# Cloud Function deployment
# Code to deploy the cloud_function; requires configuration of source url
# Cloud Function creation
resource "google_cloudfunctions_function" "strava_function" {
  name        = "strava-api-function"
  description = "Strava Function to export from Strava API to Bigquery"
  runtime     = "python38"
  entry_point = "run"
  project     = var.project
  region      = var.region
  trigger_http          = true
  available_memory_mb   = 128
  timeout               = 60
  max_instances         = 1
  service_account_email = "strava-d199d@appspot.gserviceaccount.com"
  source_repository {
    url = "https://github.com/maxhabra/strava-api-function"
  }
}
