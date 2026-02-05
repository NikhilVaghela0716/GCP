#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message (UPDATED)
echo "${TEAL_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${TEAL_TEXT}${BOLD_TEXT}      SUBSCRIBE NIKHIL VAGHELA - INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${TEAL_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the ZONE: ${RESET_FORMAT}" ZONE
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the REGION_2: ${RESET_FORMAT}" REGION_2

echo "${LIME_TEXT}${BOLD_TEXT}Starting Progress...${RESET_FORMAT}"

export ZONE REGION_2
export REGION="${ZONE%-*}"
export PROJECT_ID=$(gcloud config get-value project)

gcloud compute networks create managementnet --subnet-mode=custom

gcloud compute networks subnets create managementsubnet-1 \
--network=managementnet --region=$REGION --range=10.130.0.0/20

gcloud compute networks create privatenet --subnet-mode=custom

gcloud compute networks subnets create privatesubnet-1 \
--network=privatenet --region=$REGION --range=172.16.0.0/24

gcloud compute networks subnets create privatesubnet-2 \
--network=privatenet --region=$REGION_2 --range=172.20.0.0/20

gcloud compute networks list
gcloud compute networks subnets list --sort-by=NETWORK

gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp \
--direction=INGRESS --priority=1000 --network=managementnet \
--action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0

gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp \
--direction=INGRESS --priority=1000 --network=privatenet \
--action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0

gcloud compute firewall-rules list --sort-by=NETWORK

gcloud compute instances create managementnet-vm-1 \
--project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-micro \
--subnet=managementsubnet-1

gcloud compute instances create privatenet-vm-1 \
--project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-micro \
--subnet=privatesubnet-1

gcloud compute instances create vm-appliance \
--project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-standard-4 \
--network-interface=subnet=privatesubnet-1 \
--network-interface=subnet=managementsubnet-1 \
--network-interface=subnet=mynetwork

# Final message (UPDATED COLORS)
echo
echo "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}      LAB COMPLETED SUCCESSFULLY - NIKHIL VAGHELA        ${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo "${PURPLE_TEXT}${BOLD_TEXT}Don't forget to Like, Share & Subscribe 🚀${RESET_FORMAT}"
