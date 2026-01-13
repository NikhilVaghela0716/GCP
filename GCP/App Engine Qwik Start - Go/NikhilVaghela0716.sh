#!/bin/bash

# =========================
# COLOR DEFINITIONS
# =========================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

RESET_FORMAT=$'\033[0m'

# TEXT FORMATTING
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}   🚀 GOOGLE CLOUD APP ENGINE LAB | NIKHIL VAGHELA 🚀              ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# =========================
# CONFIGURATION
# =========================
gcloud config set compute/region $REGION
gcloud config set project $DEVSHELL_PROJECT_ID

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling App Engine API...${RESET_FORMAT}"
gcloud services enable appengine.googleapis.com

# =========================
# SOURCE CODE SETUP
# =========================
echo "${CYAN_TEXT}${BOLD_TEXT}Cloning Golang samples repository...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/golang-samples.git

cd golang-samples/appengine/go11x/helloworld

echo "${CYAN_TEXT}${BOLD_TEXT}Installing App Engine Go SDK...${RESET_FORMAT}"
sudo apt-get install -y google-cloud-sdk-app-engine-go

# =========================
# APP ENGINE DEPLOYMENT
# =========================
echo "${GREEN_TEXT}${BOLD_TEXT}Creating App Engine application...${RESET_FORMAT}"
gcloud app create --region=$REGION

echo "${GREEN_TEXT}${BOLD_TEXT}Deploying application...${RESET_FORMAT}"
gcloud app deploy --quiet

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}        ✅ LAB COMPLETED SUCCESSFULLY!                        ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
