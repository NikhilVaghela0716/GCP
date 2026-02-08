#!/bin/bash

# ====================================================
# COLOR DEFINITIONS
# ====================================================
BLUE_TEXT=$(tput setaf 4)
RED_TEXT=$(tput setaf 1)
BOLD_TEXT=$(tput bold)
RESET_FORMAT=$(tput sgr0)

clear

# ====================================================
# WELCOME MESSAGE
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}           GOOGLE CLOUD & GITHUB LAB | EXECUTION STARTED          ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ====================================================
# STEP 1: CONFIGURATION
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 1: Configuring Project and Region${RESET_FORMAT}"

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/region $REGION

echo "${BLUE_TEXT}Project ID: $PROJECT_ID${RESET_FORMAT}"
echo "${BLUE_TEXT}Region: $REGION${RESET_FORMAT}"
echo

# ====================================================
# STEP 2: ENABLE APIS
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 2: Enabling Google Cloud APIs...${RESET_FORMAT}"

gcloud services enable \
cloudresourcemanager.googleapis.com \
container.googleapis.com \
cloudbuild.googleapis.com \
containerregistry.googleapis.com \
run.googleapis.com \
secretmanager.googleapis.com

echo "${BLUE_TEXT}Waiting 60 seconds for API propagation...${RESET_FORMAT}"
sleep 60
echo "${BLUE_TEXT}APIs enabled successfully.${RESET_FORMAT}"
echo

# ====================================================
# STEP 3: IAM PERMISSIONS
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Granting Secret Manager Admin Role...${RESET_FORMAT}"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com \
--role=roles/secretmanager.admin

echo "${BLUE_TEXT}IAM policy updated.${RESET_FORMAT}"
echo

# ====================================================
# STEP 4: GITHUB CLI SETUP
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 4: Installing and Configuring GitHub CLI${RESET_FORMAT}"

echo "${BLUE_TEXT}Installing 'gh' tool...${RESET_FORMAT}"
curl -sS https://webi.sh/gh | sh

# Refresh environment to pick up 'gh' path if needed, or rely on script execution flow
# Note: 'gh auth login' requires user interaction
echo
echo "${RED_TEXT}${BOLD_TEXT}ACTION REQUIRED: Please authenticate with GitHub below.${RESET_FORMAT}"
gh auth login

echo "${BLUE_TEXT}Configuring Git User Details...${RESET_FORMAT}"
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"

echo "${BLUE_TEXT}GitHub User: ${GITHUB_USERNAME}${RESET_FORMAT}"
echo "${BLUE_TEXT}Email Configured: ${USER_EMAIL}${RESET_FORMAT}"



# ====================================================
# FINAL WARNING
# ====================================================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT} Follow the video and don’t run commands without watching it. ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
