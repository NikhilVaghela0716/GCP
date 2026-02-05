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
# PRE-FLIGHT CHECKS
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ====================================================
# ZONE & REGION CONFIGURATION
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Attempting to automatically determine your default GCP zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Default zone not found.${RESET_FORMAT}"
    read -p "${RED_TEXT}${BOLD_TEXT}Please enter the zone: ${RESET_FORMAT}" ZONE
fi

echo "${BLUE_TEXT}${BOLD_TEXT}Attempting to automatically determine your default GCP region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
    if [ -n "$ZONE" ]; then
        REGION=$(echo "$ZONE" | sed 's/-[a-z]$//')
        echo "${RED_TEXT}${BOLD_TEXT}Default region not found. Deriving region from zone: $REGION${RESET_FORMAT}"
    else
        echo "${RED_TEXT}${BOLD_TEXT}Critical: Cannot determine region as zone is also not set.${RESET_FORMAT}"
        exit 1
    fi
fi

echo
echo "${BLUE_TEXT}Using Zone: $ZONE${RESET_FORMAT}"
echo "${BLUE_TEXT}Using Region: $REGION${RESET_FORMAT}"
echo

# ====================================================
# VPC 1: LABNET SETUP
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a custom-mode VPC network named 'labnet'...${RESET_FORMAT}"
gcloud compute networks create labnet --subnet-mode=custom

echo "${BLUE_TEXT}${BOLD_TEXT}Creating subnet 'labnet-sub' in region $REGION with IP range 10.0.0.0/28...${RESET_FORMAT}"
gcloud compute networks subnets create labnet-sub \
   --network labnet \
   --region "$REGION" \
   --range 10.0.0.0/28

echo "${BLUE_TEXT}${BOLD_TEXT}Listing all VPC networks in the project...${RESET_FORMAT}"
gcloud compute networks list

echo "${BLUE_TEXT}${BOLD_TEXT}Setting up firewall rule 'labnet-allow-internal' (Allow ICMP/SSH)...${RESET_FORMAT}"
gcloud compute firewall-rules create labnet-allow-internal \
    --network=labnet \
    --action=ALLOW \
    --rules=icmp,tcp:22 \
    --source-ranges=0.0.0.0/0

# ====================================================
# VPC 2: PRIVATENET SETUP
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a custom-mode VPC network named 'privatenet'...${RESET_FORMAT}"
gcloud compute networks create privatenet --subnet-mode=custom

echo "${BLUE_TEXT}${BOLD_TEXT}Creating subnet 'private-sub' in region $REGION with IP range 10.1.0.0/28...${RESET_FORMAT}"
gcloud compute networks subnets create private-sub \
    --network=privatenet \
    --region="$REGION" \
    --range 10.1.0.0/28

echo "${BLUE_TEXT}${BOLD_TEXT}Setting up firewall rule 'privatenet-deny' (Deny ICMP/SSH)...${RESET_FORMAT}"
gcloud compute firewall-rules create privatenet-deny \
    --network=privatenet \
    --action=DENY \
    --rules=icmp,tcp:22 \
    --source-ranges=0.0.0.0/0

echo "${BLUE_TEXT}${BOLD_TEXT}Listing all firewall rules...${RESET_FORMAT}"
gcloud compute firewall-rules list --sort-by=NETWORK

# ====================================================
# VM INSTANCE CREATION
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Launching VM 'pnet-vm' in 'private-sub'...${RESET_FORMAT}"
gcloud compute instances create pnet-vm \
--zone="$ZONE" \
--machine-type=n1-standard-1 \
--subnet=private-sub

echo "${BLUE_TEXT}${BOLD_TEXT}Launching VM 'lnet-vm' in 'labnet-sub'...${RESET_FORMAT}"
gcloud compute instances create lnet-vm \
--zone="$ZONE" \
--machine-type=n1-standard-1 \
--subnet=labnet-sub

# ====================================================
# COMPLETION FOOTER
# ====================================================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}                 ✅ LAB COMPLETED SUCCESSFULLY!               ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
