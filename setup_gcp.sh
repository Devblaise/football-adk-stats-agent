#!/bin/bash

set -e # Stop if any command fails

#---- Configure gcloud CLI --------
YOUR_EMAIL="your_email_name@example.com"
PROJECT_ID="football-stats-agent"
LOCATION="europe-west1"
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

echo "Setting up IAM and Artifact Registry for project: $PROJECT_ID"
echo "Project Number: $PROJECT_NUMBER"

#---- Your account --------
echo "\n Granting roles to your account ($YOUR_EMAIL)..."
for ROLE in \
    roles/mcp.toolUser \
    roles/cloudapiregistry.viewer \
    roles/bigquery.dataViewer \
    roles/bigquery.jobUser \
    roles/aiplatform.user \
    roles/storage.objectViewer; do
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="user:${YOUR_EMAIL}" \
        --role="$ROLE" \
        --quiet
    echo "Granted $ROLE to $YOUR_EMAIL"
done


# ---- Compute service account (used by Cloud Run) --------
echo "\n Granting roles to the compute service account..."
SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
for ROLE in \
    roles/mcp.toolUser \
    roles/cloudapiregistry.viewer \
    roles/bigquery.dataViewer \
    roles/bigquery.jobUser \
    roles/aiplatform.user; do
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SA}" \
        --role="$ROLE" \
        --quiet
    echo "Granted $ROLE to $SA"
done

#---- Agent Engine service account (used by Agent Engine) --------
echo "\n Granting roles to the Agent Engine service account..."
RE_SA="service-${PROJECT_NUMBER}@gcp-sa-aiplatform-re.iam.gserviceaccount.com"
for ROLE in \
    roles/mcp.toolUser \
    roles/cloudapiregistry.viewer; do
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${RE_SA}" \
        --role="$ROLE" \
        --quiet && echo "Granted $ROLE to $RE_SA" || echo " $ROLE skipped (SA might not exist yet)"
done

#---- Artifact Registry --------
echo "\n  Setting up Artifact Registry Repository..."
gcloud artifacts repositories create internal-images \
    --repository-format=docker \
    --location=$LOCATION \
    --description="Football Stats Agent Docker images" \
    --quiet 
echo " Repository Created"

echo "\n Configuring Docker authentication for Artifact Registry..."
gcloud auth configure-docker $LOCATION-docker.pkg.dev --quiet
echo " Docker authentication configured"

echo "\nSetup complete! You can now build and deploy your agent."