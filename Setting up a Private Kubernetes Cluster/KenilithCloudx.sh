#!/bin/bash

# Color Configuration
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo -e "${BLUE_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${BLUE_TEXT}         🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀              ${RESET_FORMAT}"
echo -e "${BLUE_TEXT}==================================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}  >> Initializing Lab Environment... Please Wait <<${RESET_FORMAT}"
echo ""

# ========================= ZONE INPUT =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Enter Zone Configuration${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -ne "${BLUE_TEXT}${BOLD_TEXT}  Please enter the Zone (e.g., us-central1-a): ${RESET_FORMAT}"
read ZONE
REGION="${ZONE%-*}"

echo -e "${BLUE_TEXT}  ✔ Zone   : ${RED_TEXT}${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  ✔ Region : ${RED_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo ""

echo -e "${BLUE_TEXT}  >> Applying zone configuration...${RESET_FORMAT}"
gcloud config set compute/zone "$ZONE" --quiet
echo ""

# ========================= TASK 2: PRIVATE CLUSTER =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Task 2: Creating Private Cluster (private-cluster)...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud beta container clusters create private-cluster \
    --enable-private-nodes \
    --master-ipv4-cidr 172.16.0.16/28 \
    --enable-ip-alias \
    --create-subnetwork "" \
    --zone "$ZONE" \
    --quiet
echo ""

# ========================= TASK 4: MASTER AUTHORIZED NETWORKS =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Task 4: Creating source-instance VM for Connectivity Test...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud compute instances create source-instance \
    --zone="$ZONE" \
    --machine-type=e2-medium \
    --scopes 'https://www.googleapis.com/auth/cloud-platform' \
    --quiet
echo ""

echo -e "${BLUE_TEXT}  >> Fetching NAT IP of source-instance...${RESET_FORMAT}"
NAT_IP=$(gcloud compute instances describe source-instance \
    --zone="$ZONE" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo -e "${BLUE_TEXT}  ✔ Source Instance NAT IP: ${RED_TEXT}${BOLD_TEXT}${NAT_IP}${RESET_FORMAT}"
echo ""

echo -e "${BLUE_TEXT}  >> Authorizing NAT IP for Master Access on private-cluster...${RESET_FORMAT}"
gcloud container clusters update private-cluster \
    --enable-master-authorized-networks \
    --master-authorized-networks "${NAT_IP}/32" \
    --zone "$ZONE" \
    --quiet
echo ""

# ========================= TASK 5: CLEAN UP =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}  >> Task 5: Deleting private-cluster (Cleanup)...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud container clusters delete private-cluster --zone="$ZONE" --quiet
echo ""

# ========================= TASK 6: CUSTOM SUBNETWORK =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Task 6: Creating Custom Subnetwork (my-subnet)...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud compute networks subnets create my-subnet \
    --network default \
    --range 10.0.4.0/22 \
    --enable-private-ip-google-access \
    --region="$REGION" \
    --secondary-range my-svc-range=10.0.32.0/20,my-pod-range=10.4.0.0/14 \
    --quiet
echo ""

echo -e "${BLUE_TEXT}  >> Creating private-cluster2 using Custom Subnetwork...${RESET_FORMAT}"
gcloud beta container clusters create private-cluster2 \
    --enable-private-nodes \
    --enable-ip-alias \
    --master-ipv4-cidr 172.16.0.32/28 \
    --subnetwork my-subnet \
    --services-secondary-range-name my-svc-range \
    --cluster-secondary-range-name my-pod-range \
    --zone="$ZONE" \
    --quiet
echo ""

echo -e "${BLUE_TEXT}  >> Authorizing NAT IP for Master Access on private-cluster2...${RESET_FORMAT}"
gcloud container clusters update private-cluster2 \
    --enable-master-authorized-networks \
    --master-authorized-networks "${NAT_IP}/32" \
    --zone="$ZONE" \
    --quiet
echo ""

# =========================
# COMPLETION FOOTER
# =========================
echo -e "${RED_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${RED_TEXT}            ✅  LAB COMPLETED SUCCESSFULLY !  ✅               ${RESET_FORMAT}"
echo -e "${RED_TEXT}==================================================================${RESET_FORMAT}"
echo ""
echo -e "${BLUE_TEXT}  Thank you for learning with Kenilith Cloudx!${RESET_FORMAT}"
echo -e "${RED_TEXT}  Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  👉  https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo ""
