#!/bin/bash

# ================= COLOR DEFINITIONS =================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[1;31m'
GREEN_TEXT=$'\033[1;32m'
YELLOW_TEXT=$'\033[1;33m'
BLUE_TEXT=$'\033[1;34m'
MAGENTA_TEXT=$'\033[1;35m'
CYAN_TEXT=$'\033[1;36m'
WHITE_TEXT=$'\033[1;37m'
GOLD_TEXT=$'\033[38;5;220m'
PURPLE_TEXT=$'\033[38;5;141m'
TEAL_TEXT=$'\033[38;5;44m'

RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# ================= WELCOME MESSAGE =================
echo -e "${GOLD_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}   🚀 INITIATING KUBERNETES LOADBALANCER LAB EXECUTION 🚀  ${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo -e "${CYAN_TEXT}${BOLD_TEXT}Welcome to Building a Kubernetes Service with LoadBalancer${RESET_FORMAT}"
echo

# ================= AUTH =================
echo -e "${BLUE_TEXT}${BOLD_TEXT}🔐 Verifying gcloud authentication${RESET_FORMAT}"
gcloud auth list

# ================= CONFIG =================
echo -e "${TEAL_TEXT}${BOLD_TEXT}📍 Fetching project zone & region${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

# ================= GKE CLUSTER =================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}☸️ Creating GKE cluster (lab-cluster)${RESET_FORMAT}"
gcloud container clusters create --machine-type=e2-medium --zone=$ZONE lab-cluster

echo -e "${BLUE_TEXT}${BOLD_TEXT}🔑 Fetching cluster credentials${RESET_FORMAT}"
gcloud container clusters get-credentials lab-cluster

# ================= DEPLOY APP =================
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}🚀 Deploying hello-server application${RESET_FORMAT}"
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0

echo -e "${TEAL_TEXT}${BOLD_TEXT}🌐 Exposing service using LoadBalancer${RESET_FORMAT}"
kubectl expose deployment hello-server --type=LoadBalancer --port 8080

# ================= CLEANUP =================
echo -e "${RED_TEXT}${BOLD_TEXT}🧹 Deleting GKE cluster${RESET_FORMAT}"
gcloud container clusters delete lab-cluster

# ================= FINAL MESSAGE =================
echo
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}      🎉 LAB COMPLETED SUCCESSFULLY 🎉                  ${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo -e "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo -e "${PURPLE_TEXT}${BOLD_TEXT}Subscribe for more Google Cloud Labs 🚀${RESET_FORMAT}"
echo
