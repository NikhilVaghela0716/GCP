#!/bin/bash

# Define color variables
RED=$'\033[0;91m'
BLUE=$'\033[0;94m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

clear

# =========================
# HEADER
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}        🚀 GOOGLE CLOUD OPS | Kenilith Cloudx 🚀                ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"

# Step 1: Auth Check
echo "${RED}${BOLD}[ACTION]${RESET} ${BLUE}Verifying Google Cloud Authentication...${RESET}"
gcloud auth list

# Step 2: Zone Extraction
echo "${RED}${BOLD}[ACTION]${RESET} ${BLUE}Identifying project default zone...${RESET}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 3: Instance Creation
echo "${RED}${BOLD}[ACTION]${RESET} ${BLUE}Deploying 'subscribe' Compute Instance (Windows 2022)...${RESET}"
gcloud compute instances create subscribe \
    --project=$DEVSHELL_PROJECT_ID \
    --zone $ZONE \
    --machine-type=e2-medium \
    --create-disk=auto-delete=yes,boot=yes,device-name=subscribe,image=projects/windows-cloud/global/images/windows-server-2022-dc-v20230913,mode=rw,size=50,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced 

# Wait Period
echo "${RED}${BOLD}[WAIT]${RESET} ${BLUE}Initializing system (30s)...${RESET}"
sleep 30

# Step 4: Logs
echo "${RED}${BOLD}[ACTION]${RESET} ${BLUE}Retrieving Serial Port Logs...${RESET}"
gcloud compute instances get-serial-port-output subscribe --zone=$ZONE

# Step 5: Password Reset
echo "${RED}${BOLD}[ACTION]${RESET} ${BLUE}Generating Admin Credentials...${RESET}"
gcloud compute reset-windows-password subscribe --zone $ZONE --user admin --quiet

# =========================
# FOOTER
# =========================
echo
echo "${RED}${BOLD}==============================================================${RESET}"
echo "${RED}${BOLD}                LAB EXECUTION COMPLETE                       ${RESET}"
echo "${RED}${BOLD}==============================================================${RESET}"
echo
echo "${BLUE}${BOLD}Support: Kenilith Cloudx${RESET}"
echo "${RED}${BOLD}Channel: https://www.youtube.com/@KenilithCloudx${RESET}"
echo
