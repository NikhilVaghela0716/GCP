#!/bin/bash

# =========================
# COLOR DEFINITIONS
# =========================
BLUE_TEXT=$'\033[0;94m'
RED_TEXT=$'\033[0;91m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Fetch zone and region
ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
PROJECT_ID=$(gcloud config get-value project)

echo "${BLUE_TEXT}${BOLD_TEXT}Setting up GKE Cluster 'io' in zone $ZONE...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE
gcloud container clusters create io --zone $ZONE

echo "${BLUE_TEXT}${BOLD_TEXT}Downloading lab resources...${RESET_FORMAT}"
gcloud storage cp -r gs://spls/gsp021/* .
cd orchestrate-with-kubernetes/kubernetes

echo "${BLUE_TEXT}${BOLD_TEXT}Deploying Nginx and creating LoadBalancer...${RESET_FORMAT}"
kubectl create deployment nginx --image=nginx:1.27.0
kubectl get pods
kubectl expose deployment nginx --port 80 --type LoadBalancer
kubectl get services

echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Secrets and ConfigMaps...${RESET_FORMAT}"
kubectl create -f pods/fortune-app.yaml
kubectl create secret generic tls-certs --from-file tls/  
kubectl create configmap nginx-proxy-conf --from-file nginx/proxy.conf  
kubectl create -f pods/secure-fortune.yaml
kubectl create -f services/fortune-app.yaml

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Firewall Rules and Labels...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-fortune-nodeport --allow tcp:31000
kubectl label pods secure-fortune 'secure=enabled'

echo "${BLUE_TEXT}${BOLD_TEXT}Deploying Auth and Frontend Microservices...${RESET_FORMAT}"
kubectl create -f deployments/auth.yaml
kubectl create -f services/auth.yaml
kubectl create -f deployments/fortune-service.yaml
kubectl create -f services/fortune-service.yaml

kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf  
kubectl create -f deployments/frontend.yaml  
kubectl create -f services/frontend.yaml

kubectl get services frontend

# =========================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}         ✅ LAB COMPLETED SUCCESSFULLY!                       ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
