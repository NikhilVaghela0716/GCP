#!/bin/bash
set -euo pipefail

# =========================
# Colors & Text Formatting
# =========================
BLACK_TEXT=$'\033[0;30m'
RED_TEXT=$'\033[0;31m'
GREEN_TEXT=$'\033[0;32m'
YELLOW_TEXT=$'\033[0;33m'
BLUE_TEXT=$'\033[0;34m'
MAGENTA_TEXT=$'\033[0;35m'
CYAN_TEXT=$'\033[0;36m'
WHITE_TEXT=$'\033[0;37m'
ORANGE_TEXT=$'\033[38;5;208m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# =========================
# Config (fill these in / export before running)
# =========================
REGION="${REGION:-us-central1}"
FUNCTION_NAME="${FUNCTION_NAME:-nodejs-storage-function}"
HTTP_FUNCTION="${HTTP_FUNCTION:-nodejs-http-function}"
# DEVSHELL_PROJECT_ID is normally already set by Cloud Shell.
DEVSHELL_PROJECT_ID="${DEVSHELL_PROJECT_ID:?DEVSHELL_PROJECT_ID is not set}"

# =========================
# Header
# =========================
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | KenilithCloudX               ${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

sleep 30

PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$DEVSHELL_PROJECT_ID" --format='value(project_number)')

# Correct way to fetch the Cloud Storage service agent for Pub/Sub notifications
SERVICE_ACCOUNT=$(gcloud storage service-agent --project="$DEVSHELL_PROJECT_ID")

gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
  --member "serviceAccount:$SERVICE_ACCOUNT" \
  --role roles/pubsub.publisher

gsutil mb -l "$REGION" "gs://$DEVSHELL_PROJECT_ID"

export BUCKET="gs://$DEVSHELL_PROJECT_ID"

# =========================
# Storage-triggered (CloudEvent) function
# =========================
mkdir -p ~/"$FUNCTION_NAME" && cd ~/"$FUNCTION_NAME"
touch index.js package.json

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.cloudEvent('$FUNCTION_NAME', (cloudevent) => {
  console.log('A new event in your Cloud Storage bucket has been logged!');
  console.log(cloudevent);
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

deploy_event_function() {
  gcloud functions deploy "$FUNCTION_NAME" \
    --gen2 \
    --runtime nodejs20 \
    --entry-point "$FUNCTION_NAME" \
    --source . \
    --region "$REGION" \
    --trigger-bucket "$BUCKET" \
    --trigger-location "$REGION" \
    --max-instances 2 \
    --quiet
}

# Loop until the Cloud Run service is created
until gcloud run services describe "$FUNCTION_NAME" --region "$REGION" &> /dev/null; do
  deploy_event_function
  if gcloud run services describe "$FUNCTION_NAME" --region "$REGION" &> /dev/null; then
    echo "Cloud Run service is created. Exiting the loop."
    break
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 10
  fi
done

cd ..

# =========================
# HTTP-triggered function
# =========================
mkdir -p ~/"$HTTP_FUNCTION" && cd ~/"$HTTP_FUNCTION"
touch index.js package.json

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.http('$HTTP_FUNCTION', (req, res) => {
  res.status(200).send('awesome lab');
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

deploy_http_function() {
  gcloud functions deploy "$HTTP_FUNCTION" \
    --gen2 \
    --runtime nodejs20 \
    --entry-point "$HTTP_FUNCTION" \
    --source . \
    --region "$REGION" \
    --trigger-http \
    --timeout 600s \
    --max-instances 2 \
    --min-instances 1 \
    --quiet
}

# Loop until the Cloud Run service is created
until gcloud run services describe "$HTTP_FUNCTION" --region "$REGION" &> /dev/null; do
  deploy_http_function
  if gcloud run services describe "$HTTP_FUNCTION" --region "$REGION" &> /dev/null; then
    echo "Cloud Run service is created. Exiting the loop."
    break
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 10
  fi
done

# =========================
# Footer
# =========================
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}                     ✅ LAB FINISHED!                             ${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo -e "${CYAN_TEXT}${BOLD_TEXT}🎉 Congratulations! Your Google Cloud Lab has been completed.${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}🙏 Thank you for learning with KenilithCloudX!${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}${BOLD_TEXT}📢 Subscribe for more hands-on Google Cloud Labs:${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
