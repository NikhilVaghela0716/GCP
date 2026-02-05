#!/bin/bash

# =========================
# COLOR DEFINITIONS
# =========================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[1;31m'
GREEN_TEXT=$'\033[1;32m'
YELLOW_TEXT=$'\033[1;33m'
BLUE_TEXT=$'\033[1;34m'
MAGENTA_TEXT=$'\033[1;35m'
CYAN_TEXT=$'\033[1;36m'
WHITE_TEXT=$'\033[1;37m'

RESET_FORMAT=$'\033[0m'

# TEXT FORMATTING
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}        🚀 GOOGLE APP ENGINE PHP LAB - NIKHIL VAGHELA         ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Hands-on Google Cloud • App Engine • PHP Deployment${RESET_FORMAT}"
echo "${YELLOW_TEXT}📺 Subscribe for more GCP Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo

# =========================
# REGION INPUT
# =========================
echo "${GREEN_TEXT}${BOLD_TEXT}🌍 Enter your App Engine region:${RESET_FORMAT}"
read REGION
echo

# =========================
# AUTH & API ENABLEMENT
# =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}🔐 Checking GCP Authentication...${RESET_FORMAT}"
gcloud auth list

echo "${YELLOW_TEXT}${BOLD_TEXT}⚙️ Enabling App Engine API...${RESET_FORMAT}"
gcloud services enable appengine.googleapis.com

# =========================
# CLONE SAMPLE APP
# =========================
echo "${CYAN_TEXT}${BOLD_TEXT}📥 Cloning PHP App Engine sample...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/php-docs-samples.git
cd php-docs-samples/appengine/standard/helloworld

sleep 30

# =========================
# APP ENGINE SETUP
# =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}🚀 Creating App Engine application...${RESET_FORMAT}"
gcloud app create --region=$REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Deploying application...${RESET_FORMAT}"
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
