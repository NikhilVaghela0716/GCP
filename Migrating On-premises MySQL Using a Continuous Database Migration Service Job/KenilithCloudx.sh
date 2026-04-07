#!/bin/bash
# Define color variables
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

clear
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}            🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀             ${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo ""

echo -e "${BLUE_TEXT}${BOLD_TEXT}Please enter the connection profile details:${RESET_FORMAT}"
read -p "$(echo -e "${BOLD_TEXT}${BLUE_TEXT}Enter the connection profile ID (unique identifier): ${RESET_FORMAT}")" CONNECTION_PROFILE_ID
read -p "$(echo -e "${BOLD_TEXT}${BLUE_TEXT}Enter the connection profile display name: ${RESET_FORMAT}")" CONNECTION_PROFILE_NAME
read -p "$(echo -e "${BOLD_TEXT}${BLUE_TEXT}Enter the host or IP address: ${RESET_FORMAT}")" HOST_OR_IP
read -p "$(echo -e "${BOLD_TEXT}${BLUE_TEXT}Enter the region: ${RESET_FORMAT}")" REGION

# Variables
DATABASE_ENGINE="MYSQL"
USERNAME="admin"
PASSWORD="changeme"
PORT=3306

# Check if profile exists
EXISTS=$(gcloud database-migration connection-profiles describe "$CONNECTION_PROFILE_ID" --location="$REGION" --quiet --format="value(name)" 2>/dev/null)
if [ "$EXISTS" == "" ]; then
  gcloud database-migration connection-profiles create mysql "$CONNECTION_PROFILE_ID" \
    --display-name="$CONNECTION_PROFILE_NAME" \
    --region="$REGION" \
    --host="$HOST_OR_IP" \
    --port=$PORT \
    --username="$USERNAME" \
    --password="$PASSWORD"
  echo -e "${BLUE_TEXT}${BOLD_TEXT}Connection profile '${CONNECTION_PROFILE_NAME}' (ID: ${CONNECTION_PROFILE_ID}) created successfully in region '${REGION}' with database engine '${DATABASE_ENGINE}'.${NO_COLOR}"
else
  echo -e "${RED_TEXT}${BOLD_TEXT}Connection profile with ID '${CONNECTION_PROFILE_ID}' already exists in region '${REGION}'. No new profile was created.${NO_COLOR}"
fi

# =========================
# COMPLETION FOOTER
# =========================
echo -e "${RED_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}                  LAB COMPLETED SUCCESSFULLY !                   ${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo ""
echo -e "${BLUE_TEXT}${BOLD_TEXT}  Thanks for learning with Kenilith Cloudx${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}  Subscribe for more Google Cloud Labs :${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo ""
