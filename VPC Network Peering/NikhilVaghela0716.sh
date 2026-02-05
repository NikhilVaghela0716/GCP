#!/bin/bash

# =========================
# COLOR DEFINITIONS
# =========================
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}            🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀               ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo

# Project 1 Setup
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export REGION_1="${ZONE%-*}"
export REGION_2="${ZONE_2%-*}"

echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Project A and Network...${RESET_FORMAT}"
gcloud config set project $PROJECT_ID
gcloud compute networks create network-a --subnet-mode custom
gcloud compute networks subnets create network-a-subnet --network network-a \
    --range 10.0.0.0/16 --region $REGION_1

gcloud compute instances create vm-a --zone $ZONE --network network-a --subnet network-a-subnet --machine-type e2-small
gcloud compute firewall-rules create network-a-fw --network network-a --allow tcp:22,icmp

# Project 2 Setup
echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Project B and Network...${RESET_FORMAT}"
gcloud config set project $PROJECT_ID_2
gcloud compute networks create network-b --subnet-mode custom
gcloud compute networks subnets create network-b-subnet --network network-b \
    --range 10.8.0.0/16 --region $REGION_2

gcloud compute instances create vm-b --zone $ZONE_2 --network network-b --subnet network-b-subnet --machine-type e2-small
gcloud compute firewall-rules create network-b-fw --network network-b --allow tcp:22,icmp

# Peering Setup (A to B)
echo "${BLUE_TEXT}${BOLD_TEXT}Establishing Peering from Network A to B...${RESET_FORMAT}"
gcloud config set project $PROJECT_ID
gcloud compute networks peerings create peer-ab \
    --network=network-a \
    --peer-project=$PROJECT_ID_2 \
    --peer-network=network-b 

# Peering Setup (B to A)
echo "${BLUE_TEXT}${BOLD_TEXT}Establishing Peering from Network B to A...${RESET_FORMAT}"
gcloud config set project $PROJECT_ID_2
gcloud compute networks peerings create peer-ba \
    --network=network-b \
    --peer-project=$PROJECT_ID \
    --peer-network=network-a

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${RED}${BOLD}==============================================================${RESET}"
echo "${RED}${BOLD}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET}"
echo "${RED}${BOLD}==============================================================${RESET}"
echo
echo "${BLUE}${BOLD}🙏 Thanks for learning with Nikhil Vaghela${RESET}"
echo "${RED}${BOLD}📢 Subscribe for more Google Cloud Labs:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@Nikhil-Vaghela0716${RESET}"
echo
