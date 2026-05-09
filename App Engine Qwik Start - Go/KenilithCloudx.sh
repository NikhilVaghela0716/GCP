#!/bin/bash
# =========================
# COLOR DEFINITIONS
# =========================
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}        🚀 GOOGLE CLOUD APP ENGINE LAB | KenilithCloudX          ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# =========================
# CONFIGURATION
# =========================
gcloud config set compute/region $REGION
gcloud config set project $DEVSHELL_PROJECT_ID

echo "${RED_TEXT}${BOLD_TEXT}>>> Setting up project configuration...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}>>> Enabling App Engine API — please wait...${RESET_FORMAT}"
gcloud services enable appengine.googleapis.com

# =========================
# SOURCE CODE SETUP
# =========================
echo "${RED_TEXT}${BOLD_TEXT}>>> Fetching Golang samples from GitHub...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/golang-samples.git
cd golang-samples/appengine/go11x/helloworld

echo "${BLUE_TEXT}${BOLD_TEXT}>>> Installing App Engine Go SDK...${RESET_FORMAT}"
sudo apt-get install -y google-cloud-sdk-app-engine-go

# =========================
# APP ENGINE DEPLOYMENT
# =========================
echo "${RED_TEXT}${BOLD_TEXT}>>> Initializing App Engine application in region: $REGION...${RESET_FORMAT}"
gcloud app create --region=$REGION

echo "${BLUE_TEXT}${BOLD_TEXT}>>> Deploying your application to App Engine...${RESET_FORMAT}"
gcloud app deploy --quiet

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          ✅ DEPLOYMENT COMPLETE — LAB FINISHED!                 ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}🙏 Thank you for learning with KenilithCloudX!${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more hands-on Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
