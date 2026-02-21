#!/bin/bash

# Define text colors and formatting
RED_TEXT=$(tput setaf 1)
BLUE_TEXT=$(tput setaf 4)

RESET_FORMAT=$(tput sgr0)
BOLD_TEXT=$(tput bold)

# Spinner function
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to run command with spinner
run_with_spinner() {
    local command="$1"
    local message="$2"
    
    echo -n "${BLUE_TEXT}${BOLD_TEXT}$message... ${RESET_FORMAT}"
    (eval "$command" > /dev/null 2>&1) &
    spinner
    echo "${RED_TEXT}${BOLD_TEXT}✓${RESET_FORMAT}"
}

clear # Clear the terminal screen

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀           ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo -n "${RED_TEXT}${BOLD_TEXT}Please enter the zone: ${RESET_FORMAT}"
read ZONE
export ZONE

# Enable the required API
run_with_spinner \
    "gcloud services enable file.googleapis.com" \
    "Enabling the Filestore API"

# Create a Compute Engine instance with Debian 12 (bookworm)
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a Compute Engine instance named 'nfs-client'...${RESET_FORMAT}"
run_with_spinner \
    "gcloud compute instances create nfs-client \
    --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=http-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=nfs-client,image=projects/debian-cloud/global/images/debian-12-bookworm-v20231010,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any" \
    "Creating Compute Engine instance"

# Create a Filestore instance
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a Filestore instance named 'nfs-server'...${RESET_FORMAT}"
run_with_spinner \
    "gcloud filestore instances create nfs-server \
    --zone=$ZONE --tier=BASIC_HDD \
    --file-share=name=\"vol1\",capacity=1TB \
    --network=name=\"default\"" \
    "Creating Filestore instance"

# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Kenilith Cloudx${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
