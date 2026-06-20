#!/bin/bash

RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'
clear

# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                  🚀 GOOGLE CLOUD LAB | KenilithCloudX            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ─── AUTO-FETCH REGION ───────────────────────────────────────────────
echo "${BLUE_TEXT}${BOLD_TEXT}[INFO] Fetching project region${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
  export REGION=$(gcloud config get-value compute/region 2>/dev/null)
fi

if [ -z "$REGION" ]; then
  echo "${RED_TEXT}[ERROR] Region not found. Set manually${RESET_FORMAT}"
  read -p "Enter region (e.g. us-central1): " REGION
fi

export ZONE_A="${REGION}-b"
export ZONE_C="${REGION}-c"

export KENILITH_LABEL="kenilith"

echo "${BLUE_TEXT}  Region : ${REGION}${RESET_FORMAT}"
echo "${BLUE_TEXT}  Zone A : ${ZONE_A}${RESET_FORMAT}"
echo "${BLUE_TEXT}  Zone C : ${ZONE_C}${RESET_FORMAT}"
echo "${BLUE_TEXT}  Label  : ${KENILITH_LABEL}${RESET_FORMAT}"
echo ""

# ─── TASK 1: NETWORK & SUBNETS ───────────────────────────────────────
echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 1] Creating VPC network and subnets...${RESET_FORMAT}"

gcloud compute networks create lb-network \
  --subnet-mode=custom \
  --description=" GSP636 custom VPC network" \
  --quiet

echo "${BLUE_TEXT}  ✔ lb-network created${RESET_FORMAT}"

gcloud compute networks subnets create backend-subnet \
  --network=lb-network \
  --region=${REGION} \
  --range=10.1.2.0/24 \
  --description="backend instances subnet" \
  --quiet

echo "${BLUE_TEXT}  ✔ backend-subnet created (10.1.2.0/24)${RESET_FORMAT}"

gcloud compute networks subnets create proxy-only-subnet \
  --network=lb-network \
  --region=${REGION} \
  --range=10.129.0.0/23 \
  --purpose=REGIONAL_MANAGED_PROXY \
  --role=ACTIVE \
  --description="proxy-only subnet for internal NLB Envoy proxies" \
  --quiet

echo "${BLUE_TEXT}  ✔ proxy-only-subnet created (10.129.0.0/23)${RESET_FORMAT}"
echo ""

# ─── TASK 2: FIREWALL RULES ──────────────────────────────────────────
echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 2] Creating firewall rules${RESET_FORMAT}"

gcloud compute firewall-rules create fw-allow-ssh \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --target-tags=allow-ssh \
  --source-ranges=0.0.0.0/0 \
  --rules=tcp:22 \
  --description="allow SSH to backend and client VMs" \
  --quiet

echo "${BLUE_TEXT}  ✔ fw-allow-ssh${RESET_FORMAT}"

gcloud compute firewall-rules create fw-allow-health-check \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --target-tags=allow-health-check \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --rules=tcp:80 \
  --description="allow GCP health checker IPs to reach backends on port 80" \
  --quiet

echo "${BLUE_TEXT}  ✔ fw-allow-health-check${RESET_FORMAT}"

gcloud compute firewall-rules create fw-allow-proxy-only-subnet \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --target-tags=allow-proxy-only-subnet \
  --source-ranges=10.129.0.0/23 \
  --rules=tcp:80 \
  --description="allow proxy-only-subnet (Envoy) traffic to backends on port 80" \
  --quiet

echo "${BLUE_TEXT}  ✔ fw-allow-proxy-only-subnet${RESET_FORMAT}"
echo ""

# ─── TASK 3: INSTANCE TEMPLATE & MIGs ───────────────────────────────
echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 3] Creating instance template...${RESET_FORMAT}"

gcloud compute instance-templates create int-tcp-proxy-backend-template \
  --region=${REGION} \
  --network=lb-network \
  --subnet=backend-subnet \
  --tags=allow-ssh,allow-health-check,allow-proxy-only-subnet \
  --description="backend template for GSP636 internal proxy NLB" \
  --metadata=startup-script='#! /bin/bash
# GSP636 backend startup script
apt-get update
apt-get install apache2 -y
a2ensite default-ssl
a2enmod ssl
vm_hostname="$(curl -H "Metadata-Flavor:Google" \
http://metadata.google.internal/computeMetadata/v1/instance/name)"
echo "Page served from: $vm_hostname" | \
tee /var/www/html/index.html
systemctl restart apache2' \
  --quiet

echo "${BLUE_TEXT}  ✔ int-tcp-proxy-backend-template created${RESET_FORMAT}"
echo ""

echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 3] Creating MIG mig-a in ${ZONE_A}...${RESET_FORMAT}"

gcloud compute instance-groups managed create mig-a \
  --template=int-tcp-proxy-backend-template \
  --size=2 \
  --zone=${ZONE_A} \
  --description="mig-a backend group zone ${ZONE_A}" \
  --quiet

gcloud compute instance-groups managed set-named-ports mig-a \
  --named-ports=tcp80:80 \
  --zone=${ZONE_A} \
  --quiet

echo "${BLUE_TEXT}  ✔ mig-a created (zone: ${ZONE_A})${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 3] Creating MIG mig-c in ${ZONE_C}...${RESET_FORMAT}"

gcloud compute instance-groups managed create mig-c \
  --template=int-tcp-proxy-backend-template \
  --size=2 \
  --zone=${ZONE_C} \
  --description="mig-c backend group zone ${ZONE_C}" \
  --quiet

gcloud compute instance-groups managed set-named-ports mig-c \
  --named-ports=tcp80:80 \
  --zone=${ZONE_C} \
  --quiet

echo "${BLUE_TEXT}  ✔ mig-c created (zone: ${ZONE_C})${RESET_FORMAT}"
echo ""

# ─── TASK 4: LOAD BALANCER ───────────────────────────────────────────
# Reserve IP
gcloud compute addresses create int-tcp-ip-address \
    --region=$REGION \
    --subnet=backend-subnet \
    --purpose=SHARED_LOADBALANCER_VIP

# Health check
gcloud compute health-checks create tcp tcp-health-check \
--region=$REGION \
    --port=80

# Backend service
gcloud compute backend-services create my-int-tcp-lb \
    --load-balancing-scheme=INTERNAL_MANAGED \
    --protocol=TCP \
    --region=$REGION \
    --health-checks=tcp-health-check \
    --health-checks-region=$REGION \
    --port-name=tcp80

# Add MIGs
gcloud compute backend-services add-backend my-int-tcp-lb \
    --region=$REGION \
    --instance-group=mig-a \
    --instance-group-zone=${REGION}-b \
    --balancing-mode=UTILIZATION \
    --max-utilization=0.8

gcloud compute backend-services add-backend my-int-tcp-lb \
    --region=$REGION \
    --instance-group=mig-c \
    --instance-group-zone=${REGION}-c \
    --balancing-mode=UTILIZATION \
    --max-utilization=0.8

# Create target TCP proxy
gcloud compute target-tcp-proxies create my-int-tcp-lb-proxy \
    --backend-service=my-int-tcp-lb \
    --backend-service-region=$REGION

echo ""
echo "${RED_TEXT}${BOLD_TEXT}Frontend Configuration Required${RESET_FORMAT}"
echo "${BLUE_TEXT}================================${RESET_FORMAT}"
echo "${BLUE_TEXT}Name           : int-tcp-forwarding-rule${RESET_FORMAT}"
echo "${BLUE_TEXT}Subnetwork     : backend-subnet${RESET_FORMAT}"
echo "${BLUE_TEXT}IP Address     : int-tcp-ip-address${RESET_FORMAT}"
echo "${BLUE_TEXT}Port           : 110${RESET_FORMAT}"
echo "${BLUE_TEXT}Proxy Protocol : Off${RESET_FORMAT}"
echo ""
echo "${RED_TEXT}${BOLD_TEXT}Open Load Balancer:${RESET_FORMAT}"
echo "${BLUE_TEXT}https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers?project=${PROJECT_ID}${RESET_FORMAT}"
echo ""
echo "${RED_TEXT}Open: my-int-tcp-lb${RESET_FORMAT}"
echo "${RED_TEXT}Click: Add Frontend IP and port${RESET_FORMAT}"
read -p "${BLUE_TEXT}Press Enter to continue...${RESET_FORMAT}"


# ─── TASK 5: CLIENT VM ───────────────────────────────────────────────
echo "${BLUE_TEXT}${BOLD_TEXT}[TASK 5] Creating client VM${RESET_FORMAT}"

gcloud compute instances create client-vm \
  --zone=${ZONE_A} \
  --network=lb-network \
  --subnet=backend-subnet \
  --tags=allow-ssh \
  --description="internal client VM to test GSP636 NLB" \
  --quiet

echo "${BLUE_TEXT}  ✔ client-vm created in ${ZONE_A}${RESET_FORMAT}"
echo ""

# ─── WAIT FOR BACKENDS ───────────────────────────────────────────────
echo "${BLUE_TEXT}${BOLD_TEXT}[WAIT] Pausse for MIG instances ${RESET_FORMAT}"
for i in {1..5}; do
  echo "${BLUE_TEXT}  ${i}Wait$RESET_FORMAT}"
  sleep 60
done
echo ""

# ─── HEALTH CHECK ────────────────────────────────────────────────────
gcloud compute backend-services get-health my-int-tcp-lb --region=${REGION}
echo ""


echo
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          		        ✅ LAB FINISHED!                        ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}🙏 Thank you for learning with KenilithCloudX!${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more hands-on Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo

