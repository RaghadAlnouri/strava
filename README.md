# strava-api-terraform
Terraform code to deploy Strava API analytics in GCP.

[Strava](https:/strava.com) is a fitness app that tracks your activities and keeps record of your running, cycling, swimming performance and routes.

This repository contains the terraform code to create the infrastructure on GCP allowing you to retrieve your strava data and do your own data analytics with any BI Tool (Data Studio, Power BI, etc.)

The python code used for the Cloud function is [available here](https://github.com/maxhabra/strava-api-function), requires `python38` or newer.

## Pre-requisits
- A GCP project to deploy the resources in.
- Your Strava App Information via the [Getting started Page](https://developers.strava.com/docs/getting-started/).
- Storing your Strava App values in Secret Manager.

## Architecture
![Architecture](https://github.com/maxhabra/strava-api-terraform/blob/master/architecture.png?raw=true)

## Workflow
1. A Schedule (cronjob) is used to launch the Cloud Function at fixed interval (every x hours)
2. Cloud Function performs the following actions on trigger:
    - Fetches Strava API secrets stored in Secret Manager.
        - Client ID
        - Client Secret
        - App Refresh Token
    - Authenticates on the Strava API and retrieves a valid Access Token.
    - Loads Latest activities into Memory.
    - Stores latest activities in BigQuery.

The data can now be linked to your favourite analytics visualizer such as [Google Data Studio](https://cloud.google.com/bigquery/docs/visualize-data-studio#create_a_data_source) or [Microsoft Power BI](https://docs.microsoft.com/en-us/power-bi/connect-data/desktop-connect-bigquery#:~:text=To%20connect%20to%20a%20Google,BigQuery%20account%20and%20select%20Connect.).

## Terraform MAIN.TF
The main.tf code generates the following resources:
- Service Account `strava-api-sa` with the following permissions:
    - `roles/bigquery.jobUser`
    - `roles/bigquery.editor`
    - `roles/secretmanager.secretAccessor`
    - `roles/cloudfunctions.invoker`
- Secret Manager Keys
    - Client ID `strava_clientid`
    - Client Secret `strava_clientsecret`
    - Refresh Token `strava_refreshtoken`
- Bigquery Dataset `strava`
- Bigquery Table `elevate`
    - Schema is generated when building the first activities via the Function.
- (Optional) Deploys a Cloud Function with HTTP trigger
    - you can link your source repository or create the cloud function through the console

## Terraform VARIABLES.TF
- Default Project:  set your project_id.
- Default Region:   set your preferred region location.