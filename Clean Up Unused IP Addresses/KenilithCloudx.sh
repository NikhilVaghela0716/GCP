#!/bin/bash
RED=`tput setaf 1`
BLUE=`tput setaf 4`
BOLD=`tput bold`
RESET=`tput sgr0`

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}              🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀           ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

gcloud services enable cloudscheduler.googleapis.com
gcloud services enable run.googleapis.com

git clone https://github.com/GoogleCloudPlatform/gcf-automated-resource-cleanup.git
cd gcf-automated-resource-cleanup/

WORKDIR=$(pwd)
cd $WORKDIR/unused-ip

export USED_IP=used-ip-address
export UNUSED_IP=unused-ip-address

gcloud compute addresses create $USED_IP --project=$PROJECT_ID --region=$REGION
gcloud compute addresses create $UNUSED_IP --project=$PROJECT_ID --region=$REGION

gcloud compute addresses list --filter="region:($REGION)"

export USED_IP_ADDRESS=$(gcloud compute addresses describe $USED_IP \
--region=$REGION --format=json | jq -r '.address')

gcloud compute instances create static-ip-instance \
--zone=$ZONE \
--machine-type=e2-medium \
--subnet=default \
--address=$USED_IP_ADDRESS

gcloud compute addresses list --filter="region:($REGION)"

gcloud services disable cloudfunctions.googleapis.com
sleep 5
gcloud services enable cloudfunctions.googleapis.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:$PROJECT_ID@appspot.gserviceaccount.com" \
--role="roles/artifactregistry.reader"

sleep 40

gcloud functions deploy unused_ip_function \
    --runtime nodejs20 \
    --region $REGION \
    --trigger-http \
    --allow-unauthenticated

export FUNCTION_URL=$(gcloud functions describe unused_ip_function \
--region=$REGION --format=json | jq -r '.url')

gcloud app create --region $REGION

gcloud scheduler jobs create http unused-ip-job \
--schedule="* 2 * * *" \
--uri=$FUNCTION_URL \
--location=$REGION

sleep 20

gcloud scheduler jobs run unused-ip-job \
--location=$REGION

gcloud compute addresses list --filter="region:($REGION)"

sleep 20

gcloud scheduler jobs run unused-ip-job \
--location=$REGION

# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED}${BOLD}==============================================================${RESET}"
echo "${RED}${BOLD}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET}"
echo "${RED}${BOLD}==============================================================${RESET}"
echo
echo "${BLUE}${BOLD}🙏 Thanks for learning with Kenilith Cloudx${RESET}"
echo "${RED}${BOLD}📢 Subscribe for more Google Cloud Labs:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@KenilithCloudx${RESET}"
echo
