#!/bin/bash  

# ---------------------------------------------
# COLOR DEFINITIONS (BLUE & RED ONLY)
# ---------------------------------------------
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
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

# User Input
echo "${RED_TEXT}${BOLD_TEXT}Enter the second zone :${RESET_FORMAT}"
read ZONE_2
export ZONE_2

# Environment Setup
export ZONE_1=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION_1=$(echo "$ZONE_1" | cut -d '-' -f 1-2)
export REGION_2=$(echo "$ZONE_2" | cut -d '-' -f 1-2)

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Web Server Instances...${RESET_FORMAT}"

# Instance Creation
gcloud compute instances create www-1 --image-family debian-11 --image-project debian-cloud --zone $ZONE_1 --tags http-tag --metadata startup-script="#!/bin/bash
apt-get update && apt-get install apache2 -y
echo 'Server 1' > /var/www/html/index.html"

gcloud compute instances create www-2 --image-family debian-11 --image-project debian-cloud --zone $ZONE_1 --tags http-tag --metadata startup-script="#!/bin/bash
apt-get update && apt-get install apache2 -y
echo 'Server 2' > /var/www/html/index.html"

gcloud compute instances create www-3 --image-family debian-11 --image-project debian-cloud --zone $ZONE_2 --tags http-tag --metadata startup-script="#!/bin/bash
apt-get update && apt-get install apache2 -y
echo 'Server 3' > /var/www/html/index.html"

gcloud compute instances create www-4 --image-family debian-11 --image-project debian-cloud --zone $ZONE_2 --tags http-tag --metadata startup-script="#!/bin/bash
apt-get update && apt-get install apache2 -y
echo 'Server 4' > /var/www/html/index.html"

echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Network and Load Balancer Components...${RESET_FORMAT}"

gcloud compute firewall-rules create www-firewall --target-tags http-tag --allow tcp:80
gcloud compute addresses create lb-ip-cr --ip-version=IPV4 --global

# Instance Groups
gcloud compute instance-groups unmanaged create $REGION_1-resources-w --zone $ZONE_1
gcloud compute instance-groups unmanaged create $REGION_2-resources-w --zone $ZONE_2

gcloud compute instance-groups unmanaged add-instances $REGION_1-resources-w --instances www-1,www-2 --zone $ZONE_1
gcloud compute instance-groups unmanaged add-instances $REGION_2-resources-w --instances www-3,www-4 --zone $ZONE_2

# Health Checks and Backend
gcloud compute health-checks create http http-basic-check

gcloud compute instance-groups unmanaged set-named-ports $REGION_1-resources-w --named-ports http:80 --zone $ZONE_1
gcloud compute instance-groups unmanaged set-named-ports $REGION_2-resources-w --named-ports http:80 --zone $ZONE_2

gcloud compute backend-services create web-map-backend-service --protocol HTTP --health-checks http-basic-check --global

gcloud compute backend-services add-backend web-map-backend-service --balancing-mode UTILIZATION --max-utilization 0.8 --capacity-scaler 1 --instance-group $REGION_1-resources-w --instance-group-zone $ZONE_1 --global
gcloud compute backend-services add-backend web-map-backend-service --balancing-mode UTILIZATION --max-utilization 0.8 --capacity-scaler 1 --instance-group $REGION_2-resources-w --instance-group-zone $ZONE_2 --global

# URL Map and Proxy
gcloud compute url-maps create web-map --default-service web-map-backend-service
gcloud compute target-http-proxies create http-lb-proxy --url-map web-map

LB_IP_ADDRESS=$(gcloud compute addresses list --format="get(ADDRESS)")

gcloud compute forwarding-rules create http-cr-rule --address $LB_IP_ADDRESS --global --target-http-proxy http-lb-proxy --ports 80


# =========================
# FINAL MESSAGE
# =========================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}               ✅ LAB COMPLETED SUCCESSFULLY!                 ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
