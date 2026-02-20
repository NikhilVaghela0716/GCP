#!/bin/bash

RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}              🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀            ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo

read -p "$(echo -e ${BLUE_TEXT}ENTER REGION_1:${RESET_FORMAT} )" REGION1
read -p "$(echo -e ${BLUE_TEXT}ENTER REGION_2:${RESET_FORMAT} )" REGION2
read -p "$(echo -e ${BLUE_TEXT}ENTER ZONE_3:${RESET_FORMAT} )" ZONE3

export REGION3="${ZONE3%-*}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Fetching your GCP Project ID and Project Number...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
echo "${RED_TEXT}${BOLD_TEXT}Project ID set to: $PROJECT_ID${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}Project Number set to: $PROJECT_NUMBER${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛠️ Enabling OS Config API...${RESET_FORMAT}"
gcloud services enable osconfig.googleapis.com
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛡️ Creating firewall rule: allow-http...${RESET_FORMAT}"
gcloud compute firewall-rules create default-allow-http \
--direction=INGRESS --priority=1000 --network=default \
--action=ALLOW --rules=tcp:80 \
--source-ranges=0.0.0.0/0 --target-tags=http-server
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛡️ Creating firewall rule: allow-health-check...${RESET_FORMAT}"
gcloud compute firewall-rules create default-allow-health-check \
--direction=INGRESS --priority=1000 --network=default \
--action=ALLOW --rules=tcp:80 \
--source-ranges=130.211.0.0/22,35.191.0.0/16 \
--target-tags=http-server
echo

echo "${RED_TEXT}${BOLD_TEXT}📄 Creating instance template for $REGION1...${RESET_FORMAT}"
gcloud compute instance-templates create $REGION1-template \
--machine-type=e2-medium \
--network-interface=network=default \
--tags=http-server \
--region=$REGION1
echo

echo "${RED_TEXT}${BOLD_TEXT}📄 Creating instance template for $REGION2...${RESET_FORMAT}"
gcloud compute instance-templates create $REGION2-template \
--machine-type=e2-medium \
--network-interface=network=default \
--tags=http-server \
--region=$REGION2
echo

echo "${RED_TEXT}${BOLD_TEXT}🏗️ Creating Managed Instance Group in $REGION1...${RESET_FORMAT}"
gcloud compute instance-groups managed create $REGION1-mig \
--template=$REGION1-template \
--size=1 --region=$REGION1
echo

echo "${RED_TEXT}${BOLD_TEXT}📈 Enabling Autoscaling for $REGION1...${RESET_FORMAT}"
gcloud compute instance-groups managed set-autoscaling $REGION1-mig \
--region=$REGION1 --max-num-replicas=5 \
--target-cpu-utilization=0.8
echo

echo "${RED_TEXT}${BOLD_TEXT}🏗️ Creating Managed Instance Group in $REGION2...${RESET_FORMAT}"
gcloud compute instance-groups managed create $REGION2-mig \
--template=$REGION2-template \
--size=1 --region=$REGION2
echo

echo "${RED_TEXT}${BOLD_TEXT}📈 Enabling Autoscaling for $REGION2...${RESET_FORMAT}"
gcloud compute instance-groups managed set-autoscaling $REGION2-mig \
--region=$REGION2 --max-num-replicas=5 \
--target-cpu-utilization=0.8
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🩺 Creating HTTP Health Check...${RESET_FORMAT}"
gcloud compute health-checks create http http-health-check --port 80
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ Creating Backend Service...${RESET_FORMAT}"
gcloud compute backend-services create http-backend \
--protocol=HTTP \
--health-checks=http-health-check \
--global
echo

echo "${BLUE_TEXT}${BOLD_TEXT}➕ Adding REGION1 backend...${RESET_FORMAT}"
gcloud compute backend-services add-backend http-backend \
--instance-group=$REGION1-mig \
--instance-group-region=$REGION1 \
--global
echo

echo "${BLUE_TEXT}${BOLD_TEXT}➕ Adding REGION2 backend...${RESET_FORMAT}"
gcloud compute backend-services add-backend http-backend \
--instance-group=$REGION2-mig \
--instance-group-region=$REGION2 \
--global
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🗺️ Creating URL Map...${RESET_FORMAT}"
gcloud compute url-maps create http-lb \
--default-service=http-backend
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🎯 Creating Target HTTP Proxy...${RESET_FORMAT}"
gcloud compute target-http-proxies create http-lb-target-proxy \
--url-map=http-lb
echo

echo "${BLUE_TEXT}${BOLD_TEXT}➡️ Creating Global Forwarding Rule (IPv4)...${RESET_FORMAT}"
gcloud compute forwarding-rules create http-lb-forwarding-rule \
--global \
--target-http-proxy=http-lb-target-proxy \
--ports=80
echo

echo "${RED_TEXT}${BOLD_TEXT}🚀 Creating siege-vm in $ZONE3...${RESET_FORMAT}"
gcloud compute instances create siege-vm \
--zone=$ZONE3 \
--machine-type=e2-medium
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📦 Installing siege utility...${RESET_FORMAT}"
gcloud compute ssh siege-vm \
--zone=$ZONE3 \
--command="sudo apt-get update && sudo apt-get -y install siege"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛡️ Creating rate-limit security policy...${RESET_FORMAT}"
gcloud compute security-policies create rate-limit-siege \
--description="Rate limiting policy"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🚦 Adding rate-limit rule...${RESET_FORMAT}"
gcloud beta compute security-policies rules create 100 \
--security-policy=rate-limit-siege \
--expression="true" \
--action=rate-based-ban \
--rate-limit-threshold-count=50 \
--rate-limit-threshold-interval-sec=120 \
--ban-duration-sec=300 \
--conform-action=allow \
--exceed-action=deny-404 \
--enforce-on-key=IP
echo

echo "${RED_TEXT}${BOLD_TEXT}🔗 Attaching security policy to backend...${RESET_FORMAT}"
gcloud compute backend-services update http-backend \
--security-policy rate-limit-siege \
--global
echo

echo
echo "${RED}${BOLD}==============================================================${RESET}"
echo "${RED}${BOLD}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET}"
echo "${RED}${BOLD}==============================================================${RESET}"
echo
echo "${BLUE}${BOLD}🙏 Thanks for learning with Kenilith Cloudx${RESET}"
echo "${RED}${BOLD}📢 Subscribe for more Google Cloud Labs:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@KenilithCloudx${RESET}"
echo
