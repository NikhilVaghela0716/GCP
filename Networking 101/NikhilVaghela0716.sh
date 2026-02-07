#!/bin/bash

# ====================================================
# COLOR DEFINITIONS
# ====================================================
BLUE_TEXT=$(tput setaf 4)
RED_TEXT=$(tput setaf 1)
BOLD_TEXT=$(tput bold)
UNDERLINE_TEXT=$(tput smul)
RESET_FORMAT=$(tput sgr0)

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo


# ====================================================
# STEP 1: VPC NETWORK
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Custom VPC Network 'taw-custom-network'...${RESET_FORMAT}"

gcloud compute networks create taw-custom-network --subnet-mode custom

echo "${BLUE_TEXT}VPC Network created.${RESET_FORMAT}"
echo



# ====================================================
# STEP 2: SUBNETS
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Subnets in Regions: $REGION_1, $REGION_2, $REGION_3...${RESET_FORMAT}"

echo "${BLUE_TEXT}Creating subnet in $REGION_1...${RESET_FORMAT}"
gcloud compute networks subnets create subnet-$REGION_1 \
   --network taw-custom-network \
   --region $REGION_1 \
   --range 10.0.0.0/16

echo "${BLUE_TEXT}Creating subnet in $REGION_2...${RESET_FORMAT}"
gcloud compute networks subnets create subnet-$REGION_2 \
   --network taw-custom-network \
   --region $REGION_2 \
   --range 10.1.0.0/16

echo "${BLUE_TEXT}Creating subnet in $REGION_3...${RESET_FORMAT}"
gcloud compute networks subnets create subnet-$REGION_3 \
   --network taw-custom-network \
   --region $REGION_3 \
   --range 10.2.0.0/16

echo "${BLUE_TEXT}Subnets created successfully.${RESET_FORMAT}"
echo

# ====================================================
# STEP 3: FIREWALL RULES
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Firewall Rules...${RESET_FORMAT}"

echo "${BLUE_TEXT}Creating HTTP Allow Rule...${RESET_FORMAT}"
gcloud compute firewall-rules create nw101-allow-http \
--allow tcp:80 --network taw-custom-network --source-ranges 0.0.0.0/0 \
--target-tags http

echo "${BLUE_TEXT}Creating ICMP Allow Rule...${RESET_FORMAT}"
gcloud compute firewall-rules create "nw101-allow-icmp" --allow icmp --network "taw-custom-network" --source-ranges 0.0.0.0/0 --target-tags rules

echo "${BLUE_TEXT}Creating Internal Communication Rule...${RESET_FORMAT}"
gcloud compute firewall-rules create "nw101-allow-internal" --allow tcp:0-65535,udp:0-65535,icmp --network "taw-custom-network" --source-ranges "10.0.0.0/16","10.2.0.0/16","10.1.0.0/16"

echo "${BLUE_TEXT}Creating SSH Allow Rule...${RESET_FORMAT}"
gcloud compute firewall-rules create "nw101-allow-ssh" --allow tcp:22 --network "taw-custom-network" --target-tags "ssh"

echo "${BLUE_TEXT}Creating RDP Allow Rule...${RESET_FORMAT}"
gcloud compute firewall-rules create "nw101-allow-rdp" --allow tcp:3389 --network "taw-custom-network"



echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}         ✅ LAB COMPLETED SUCCESSFULLY!                       ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
