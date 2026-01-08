#!/bin/bash

# ================= COLORS =================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
ORANGE_TEXT=$'\033[38;5;214m'
TEAL_TEXT=$'\033[38;5;51m'

RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear


# ================= INPUT =================
read -p "${YELLOW_TEXT}${BOLD_TEXT}🌍 Enter REGION_1 (example: us-wese1): ${RESET_FORMAT}" REGION_1
read -p "${YELLOW_TEXT}${BOLD_TEXT}🌍 Enter REGION_2 (example: us-central1): ${RESET_FORMAT}" REGION

export REGION_1
export REGION

echo
echo -e "${TEAL_TEXT}${BOLD_TEXT}🔎 Automatically selecting zones...${RESET_FORMAT}"

export ZONE_1=$(gcloud compute zones list \
  --filter="region:($REGION_1)" \
  --format="value(name)" | head -n 1)

export ZONE_2=$(gcloud compute zones list \
  --filter="region:($REGION)" \
  --format="value(name)" | head -n 1)

# ================= VALIDATION =================
if [[ -z "$ZONE_1" || -z "$ZONE_2" ]]; then
  echo -e "${RED_TEXT}${BOLD_TEXT}❌ Invalid region entered. Please verify region names.${RESET_FORMAT}"
  exit 1
fi

echo
echo -e "${GREEN_TEXT}${BOLD_TEXT}✔ Regions & Zones Selected:${RESET_FORMAT}"
echo -e "${GREEN_TEXT}   ▸ REGION_1: ${WHITE_TEXT}$REGION_1${GREEN_TEXT} → ZONE_1: ${WHITE_TEXT}$ZONE_1${RESET_FORMAT}"
echo -e "${GREEN_TEXT}   ▸ REGION_2: ${WHITE_TEXT}$REGION${GREEN_TEXT} → ZONE_2: ${WHITE_TEXT}$ZONE_2${RESET_FORMAT}"
echo

# ================= NETWORK SETUP =================
echo -e "${ORANGE_TEXT}${BOLD_TEXT}🌐 Creating cloud VPC network...${RESET_FORMAT}"
gcloud compute networks create cloud --subnet-mode custom

echo -e "${ORANGE_TEXT}${BOLD_TEXT}🔥 Configuring cloud firewall rules...${RESET_FORMAT}"
gcloud compute firewall-rules create cloud-fw --network cloud --allow tcp:22,tcp:5001,udp:5001,icmp

echo -e "${ORANGE_TEXT}${BOLD_TEXT}📡 Creating cloud subnet...${RESET_FORMAT}"
gcloud compute networks subnets create cloud-east --network cloud \
    --range 10.0.1.0/24 --region $REGION_1

echo -e "${ORANGE_TEXT}${BOLD_TEXT}🏢 Creating on-prem VPC network...${RESET_FORMAT}"
gcloud compute networks create on-prem --subnet-mode custom

echo -e "${ORANGE_TEXT}${BOLD_TEXT}🔥 Configuring on-prem firewall rules...${RESET_FORMAT}"
gcloud compute firewall-rules create on-prem-fw --network on-prem --allow tcp:22,tcp:5001,udp:5001,icmp

echo -e "${ORANGE_TEXT}${BOLD_TEXT}📡 Creating on-prem subnet...${RESET_FORMAT}"
gcloud compute networks subnets create on-prem-central \
    --network on-prem --range 192.168.1.0/24 --region $REGION

# ================= VPN SETUP =================
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}🔐 Creating VPN gateways...${RESET_FORMAT}"
gcloud compute target-vpn-gateways create on-prem-gw1 --network on-prem --region $REGION
gcloud compute target-vpn-gateways create cloud-gw1 --network cloud --region $REGION_1

echo -e "${MAGENTA_TEXT}${BOLD_TEXT}📍 Allocating static IP addresses...${RESET_FORMAT}"
gcloud compute addresses create cloud-gw1 --region $REGION_1
gcloud compute addresses create on-prem-gw1 --region $REGION

cloud_gw1_ip=$(gcloud compute addresses describe cloud-gw1 \
    --region $REGION_1 --format='value(address)')

on_prem_gw_ip=$(gcloud compute addresses describe on-prem-gw1 \
    --region $REGION --format='value(address)')

echo -e "${MAGENTA_TEXT}${BOLD_TEXT}🔁 Creating forwarding rules...${RESET_FORMAT}"
gcloud compute forwarding-rules create cloud-1-fr-esp --ip-protocol ESP \
    --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region $REGION_1

gcloud compute forwarding-rules create cloud-1-fr-udp500 --ip-protocol UDP \
    --ports 500 --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region $REGION_1

gcloud compute forwarding-rules create cloud-fr-1-udp4500 --ip-protocol UDP \
    --ports 4500 --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region $REGION_1

gcloud compute forwarding-rules create on-prem-fr-esp --ip-protocol ESP \
    --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region $REGION

gcloud compute forwarding-rules create on-prem-fr-udp500 --ip-protocol UDP --ports 500 \
    --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region $REGION

gcloud compute forwarding-rules create on-prem-fr-udp4500 --ip-protocol UDP --ports 4500 \
    --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region $REGION

echo -e "${MAGENTA_TEXT}${BOLD_TEXT}🔗 Creating VPN tunnels...${RESET_FORMAT}"
gcloud compute vpn-tunnels create on-prem-tunnel1 --peer-address $cloud_gw1_ip \
    --target-vpn-gateway on-prem-gw1 --ike-version 2 --local-traffic-selector 0.0.0.0/0 \
    --remote-traffic-selector 0.0.0.0/0 --shared-secret=[MY_SECRET] --region $REGION

gcloud compute vpn-tunnels create cloud-tunnel1 --peer-address $on_prem_gw_ip \
    --target-vpn-gateway cloud-gw1 --ike-version 2 --local-traffic-selector 0.0.0.0/0 \
    --remote-traffic-selector 0.0.0.0/0 --shared-secret=[MY_SECRET] --region $REGION_1

# ================= COMPUTE =================
echo -e "${CYAN_TEXT}${BOLD_TEXT}🖥 Creating load test instances...${RESET_FORMAT}"
gcloud compute instances create "cloud-loadtest" --zone $ZONE_1 \
    --machine-type "e2-standard-4" --subnet "cloud-east" \
    --image-family "debian-11" --image-project "debian-cloud"

gcloud compute instances create "on-prem-loadtest" --zone $ZONE_2 \
    --machine-type "e2-standard-4" --subnet "on-prem-central" \
    --image-family "debian-11" --image-project "debian-cloud"

echo -e "${CYAN_TEXT}${BOLD_TEXT}📊 Running network performance test (iperf)...${RESET_FORMAT}"
gcloud compute ssh --zone "$ZONE_2" "on-prem-loadtest" --quiet \
 --command "sudo apt-get install -y iperf && iperf -s -i 5" &

sleep 10

gcloud compute ssh --zone "$ZONE_1" "cloud-loadtest" --quiet \
 --command "sudo apt-get install -y iperf && iperf -c 192.168.1.2 -P 20 -x C"

# ================= FINAL =================
echo
echo -e "${GREEN_TEXT}${BOLD_TEXT} 🎉 LAB COMPLETED SUCCESSFULLY 🎉 ${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}══════════════════════════════════════════════════════════${RESET_FORMAT}"
echo
echo -e "${ORANGE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}Welcome to Dr. Abhishek Cloud Tutorials${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}🔔 Subscribe: https://www.youtube.com/@drabhishek.5460${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}👍 Like • Share • Subscribe${RESET_FORMAT}"
