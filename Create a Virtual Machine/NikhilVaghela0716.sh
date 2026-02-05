#!/bin/bash

# =========================
# COLOR DEFINITIONS
# =========================
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}            🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀              ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"
gcloud compute instances create gcelab \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --tags=http-server \
  --metadata=startup-script='#!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx' \
  --scopes=https://www.googleapis.com/auth/cloud-platform

# Create firewall rule to allow HTTP traffic (if not already exists)
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server \
  --description="Allow HTTP traffic" \
  --quiet || echo "Firewall rule already exists or skipped."

# Create second instance using gcloud
gcloud compute instances create gcelab2 \
  --machine-type=e2-medium \
  --zone=$ZONE \
  --image-family=debian-11 \
  --image-project=debian-cloud

# Print External IP for gcelab
echo -e "\nAccess your NGINX site at: http://$(gcloud compute instances describe gcelab --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"

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
