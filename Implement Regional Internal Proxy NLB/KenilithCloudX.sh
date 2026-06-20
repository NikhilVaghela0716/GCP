#!/bin/bash

RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
clear

# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                  🚀 GOOGLE CLOUD LAB | KenilithCloudX            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Auto-fetch project and region/zone
echo "${RED_TEXT}Fetching project info...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project)
REGION=$(gcloud compute instances list --format="value(zone)" --limit=1 | sed 's/-[a-z]$//')
ZONE=$(gcloud compute instances list --format="value(zone)" --limit=1)
VM1=$(gcloud compute instances list --format="value(name)" | grep -v "1$" | head -1)
VM2=$(gcloud compute instances list --format="value(name)" | grep "1$" | head -1)

# Fallback: list all VMs and pick first two
if [ -z "$VM1" ] || [ -z "$VM2" ]; then
  VMS=($(gcloud compute instances list --format="value(name)"))
  VM1="${VMS[0]}"
  VM2="${VMS[1]}"
fi

echo "${BLUE_TEXT}Project : ${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo "${BLUE_TEXT}Region  : ${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo "${BLUE_TEXT}Zone    : ${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo "${BLUE_TEXT}VM1     : ${BOLD_TEXT}$VM1${RESET_FORMAT}"
echo "${BLUE_TEXT}VM2     : ${BOLD_TEXT}$VM2${RESET_FORMAT}"
echo ""

# ─── TASK 1: Instance Groups ───────────────────────────────────────────────────

echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 1] Creating Instance Groups...${RESET_FORMAT}"

echo "${RED_TEXT}Creating web-server-1 (VM: $VM1)...${RESET_FORMAT}"
gcloud compute instance-groups unmanaged create web-server-1 \
  --zone="$ZONE" \
  --project="$PROJECT_ID"

gcloud compute instance-groups unmanaged add-instances web-server-1 \
  --zone="$ZONE" \
  --instances="$VM1" \
  --project="$PROJECT_ID"

echo "${BLUE_TEXT}✔ web-server-1 created${RESET_FORMAT}"

echo "${RED_TEXT}Creating web-server-2 (VM: $VM2)...${RESET_FORMAT}"
gcloud compute instance-groups unmanaged create web-server-2 \
  --zone="$ZONE" \
  --project="$PROJECT_ID"

gcloud compute instance-groups unmanaged add-instances web-server-2 \
  --zone="$ZONE" \
  --instances="$VM2" \
  --project="$PROJECT_ID"

echo "${BLUE_TEXT}✔ web-server-2 created${RESET_FORMAT}"

# ─── TASK 2: Health Check ──────────────────────────────────────────────────────

echo ""
echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 2] Creating Health Check...${RESET_FORMAT}"

gcloud compute health-checks create tcp basic-http-check \
  --region="$REGION" \
  --port=80 \
  --project="$PROJECT_ID"

echo "${BLUE_TEXT}✔ Health check basic-http-check created${RESET_FORMAT}"

# ─── TASK 2: Static IP ─────────────────────────────────────────────────────────

echo ""
echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 2] Reserving Static External IP...${RESET_FORMAT}"

gcloud compute addresses create network-lb-ip \
  --region="$REGION" \
  --project="$PROJECT_ID"

LB_IP=$(gcloud compute addresses describe network-lb-ip \
  --region="$REGION" \
  --format="value(address)" \
  --project="$PROJECT_ID")

echo "${BLUE_TEXT}✔ Static IP reserved: ${BOLD_TEXT}$LB_IP${RESET_FORMAT}"

# ─── TASK 2: Backend Service ───────────────────────────────────────────────────

echo ""
echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 2] Creating Backend Service...${RESET_FORMAT}"

gcloud compute backend-services create network-lb-backend-service \
  --protocol=TCP \
  --region="$REGION" \
  --health-checks=basic-http-check \
  --health-checks-region="$REGION" \
  --project="$PROJECT_ID"

echo "${RED_TEXT}Adding backends...${RESET_FORMAT}"

gcloud compute backend-services add-backend network-lb-backend-service \
  --instance-group=web-server-1 \
  --instance-group-zone="$ZONE" \
  --region="$REGION" \
  --project="$PROJECT_ID"

gcloud compute backend-services add-backend network-lb-backend-service \
  --instance-group=web-server-2 \
  --instance-group-zone="$ZONE" \
  --region="$REGION" \
  --project="$PROJECT_ID"

echo "${BLUE_TEXT}✔ Backend service created with both instance groups${RESET_FORMAT}"

echo "${RED_TEXT}${BOLD_TEXT}MANUAL STEP REQUIRED${RESET_FORMAT}"
echo ""
echo "${BLUE_TEXT}Name: network-lb-backend-service${RESET_FORMAT}"
echo "${BLUE_TEXT}Health Check: basic-http-check${RESET_FORMAT}"
echo "${BLUE_TEXT}Backends: web-server-1 and web-server-2${RESET_FORMAT}"
echo "${BLUE_TEXT}Frontend IP: network-lb-ip${RESET_FORMAT}"
echo "${BLUE_TEXT}Port: 80${RESET_FORMAT}"
echo ""
echo "${RED_TEXT}Open the following URL:${RESET_FORMAT}"
echo "${BLUE_TEXT}https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers?project=$PROJECT_ID${RESET_FORMAT}"
echo ""
read -p "${RED_TEXT}${BOLD_TEXT}Create the load balancer, then press ENTER to continue...${RESET_FORMAT}"

echo "${BLUE_TEXT}✔ Backend service created with both instance groups${RESET_FORMAT}"

# ─── TASK 2: Target Pool + Forwarding Rule ─────────────────────────────────────

echo ""
echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 2] Creating Target Pool & Forwarding Rule...${RESET_FORMAT}"

gcloud compute target-pools add-instances network-lb-target-pool \
  --instances="$VM1","$VM2" \
  --instances-zone="$ZONE" \
  --region="$REGION" \
  --project="$PROJECT_ID"

echo "${RED_TEXT}Creating forwarding rule...${RESET_FORMAT}"

echo "${BLUE_TEXT}✔ Forwarding rule created${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                         ✅ LAB FINISHED!                         ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}🙏 Thank you for learning with KenilithCloudX!${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more hands-on Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
