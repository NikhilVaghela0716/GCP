#!/bin/bash

# ==========================================
# ONLY BLUE & RED COLORS
# ==========================================
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


gcloud auth list


echo "${BLUE_TEXT}${BOLD_TEXT}Fetching ZONE and REGION...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")


echo "${BLUE_TEXT}${BOLD_TEXT}Creating VPC Network vpc-net...${RESET_FORMAT}"
# ------------------------------------------------------
gcloud compute networks create vpc-net --project=$DEVSHELL_PROJECT_ID --description="Subscribe to Nikhil Vaghela YouTube Channel" --subnet-mode=custom

echo "${BLUE_TEXT}${BOLD_TEXT}Creating VPC Subnet vpc-subnet${RESET_FORMAT}"
gcloud compute networks subnets create vpc-subnet --project=$DEVSHELL_PROJECT_ID --network=vpc-net --region=$REGION --range=10.1.3.0/24 --enable-flow-logs

echo "${RED_TEXT}${BOLD_TEXT} Waiting 60 seconds for network propagation...${RESET_FORMAT}"
sleep 100

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Firewall Rule${RESET_FORMAT}"
gcloud compute firewall-rules create allow-http-ssh \
  --project=$DEVSHELL_PROJECT_ID \
  --direction=INGRESS \
  --priority=1000 \
  --network=vpc-net \
  --action=ALLOW \
  --rules=tcp:80,tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server


echo "${BLUE_TEXT}${BOLD_TEXT}Creating Apache Web Server VM: web-server...${RESET_FORMAT}"
gcloud compute instances create web-server \
  --zone=$ZONE \
  --project=$DEVSHELL_PROJECT_ID \
  --machine-type=e2-micro \
  --subnet=vpc-subnet \
  --tags=http-server \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --metadata=startup-script='#!/bin/bash
    sudo apt update
    sudo apt install apache2 -y
    sudo systemctl start apache2
    sudo systemctl enable apache2' \
  --labels=server=apache

# ------------------------------------------------------
echo "${BLUE_TEXT}${BOLD_TEXT}👉 Adding alternate HTTP firewall rule...${RESET_FORMAT}"
# ------------------------------------------------------
gcloud compute firewall-rules create allow-http-alt \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server \
    --description="Allow HTTP traffic on alternate rule"

echo "${BLUE_TEXT}${BOLD_TEXT}Creating BigQuery dataset for VPC Flow${RESET_FORMAT}"
bq mk bq_vpcflows

echo "${BLUE_TEXT}${BOLD_TEXT}Fetching Public IP of web-server${RESET_FORMAT}"
CP_IP=$(gcloud compute instances describe web-server --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
export MY_SERVER=$CP_IP

echo "${RED_TEXT}${BOLD_TEXT}Generating sample traffic 50 HTTP requests${RESET_FORMAT}"
for ((i=1;i<=50;i++)); do curl $MY_SERVER; done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Edit Firewall:${RESET_FORMAT} https://console.cloud.google.com/net-security/firewall-manager/firewall-policies/details/allow-http-ssh?project=$DEVSHELL_PROJECT_ID"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Create an export sink:${RESET_FORMAT} https://console.cloud.google.com/logs/query?project=$DEVSHELL_PROJECT_ID"
echo


echo "${RED_TEXT}${BOLD_TEXT}Asking user to continue ${RESET_FORMAT}"
while true; do
    echo -ne "${BLUE_TEXT}${BOLD_TEXT}Do you Want to proceed? (Y/n): ${RESET_FORMAT}"
    read confirm
    case "$confirm" in
        [Yy]) 
            echo "${BLUE_TEXT}Running the command...${RESET_FORMAT}"
            break
            ;;
        [Nn]|"") 
            echo "${RED_TEXT}Operation canceled.${RESET_FORMAT}"
            break
            ;;
        *) 
            echo "${RED_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}" 
            ;;
    esac
done

echo "${RED_TEXT}${BOLD_TEXT}Generating more sample traffic 100 requests${RESET_FORMAT}"
CP_IP=$(gcloud compute instances describe web-server --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
export MY_SERVER=$CP_IP
for ((i=1;i<=100;i++)); do curl $MY_SERVER; done

# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
