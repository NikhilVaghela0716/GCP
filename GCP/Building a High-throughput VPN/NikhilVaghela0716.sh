#!/bin/bash

# ================== COLOR DEFINITIONS ==================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
ORANGE_TEXT=$'\033[38;5;214m'
GOLD_TEXT=$'\033[38;5;220m'
PURPLE_TEXT=$'\033[38;5;141m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# ================== WELCOME BANNER ==================
echo "${GOLD_TEXT}${BOLD_TEXT}══════════════════════════════════════════════════════════════════${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}   🚀 Welcome to Building a High-throughput VPN Lab 🚀            ${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}══════════════════════════════════════════════════════════════════${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Subscribe for more GCP Labs${RESET_FORMAT}"
echo "${PURPLE_TEXT}${BOLD_TEXT}Channel: Nikhil Vaghela${RESET_FORMAT}"
echo

# ================== INPUT ==================
read -p "${ORANGE_TEXT}${BOLD_TEXT}Enter REGION_1 (example: us-east1): ${RESET_FORMAT}" REGION_1
read -p "${ORANGE_TEXT}${BOLD_TEXT}Enter REGION_2 (example: us-central1): ${RESET_FORMAT}" REGION

export REGION_1
export REGION

# ================== ZONE SELECTION ==================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Auto-selecting zones for both regions...${RESET_FORMAT}"

export ZONE_1=$(gcloud compute zones list \
  --filter="region:($REGION_1)" \
  --format="value(name)" | head -n 1)

export ZONE_2=$(gcloud compute zones list \
  --filter="region:($REGION)" \
  --format="value(name)" | head -n 1)

if [[ -z "$ZONE_1" || -z "$ZONE_2" ]]; then
  echo "${RED_TEXT}${BOLD_TEXT}❌ Invalid region entered. Please verify region names.${RESET_FORMAT}"
  exit 1
fi

echo "${GREEN_TEXT}${BOLD_TEXT}✔ REGION_1 → $REGION_1 | ZONE → $ZONE_1${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}✔ REGION_2 → $REGION   | ZONE → $ZONE_2${RESET_FORMAT}"
echo

# ================== NETWORK SETUP ==================
echo "${BLUE_TEXT}${BOLD_TEXT}🌐 Creating Cloud Network & Firewall...${RESET_FORMAT}"
gcloud compute networks create cloud --subnet-mode custom
gcloud compute firewall-rules create cloud-fw --network cloud --allow tcp:22,tcp:5001,udp:5001,icmp

echo "${BLUE_TEXT}${BOLD_TEXT}🌐 Creating Cloud Subnet...${RESET_FORMAT}"
gcloud compute networks subnets create cloud-east --network cloud \
    --range 10.0.1.0/24 --region $REGION_1

echo "${MAGENTA_TEXT}${BOLD_TEXT}🏢 Creating On-Prem Network & Firewall...${RESET_FORMAT}"
gcloud compute networks create on-prem --subnet-mode custom
gcloud compute firewall-rules create on-prem-fw --network on-prem --allow tcp:22,tcp:5001,udp:5001,icmp

echo "${MAGENTA_TEXT}${BOLD_TEXT}🏢 Creating On-Prem Subnet...${RESET_FORMAT}"
gcloud compute networks subnets create on-prem-central \
    --network on-prem --range 192.168.1.0/24 --region $REGION

# ================== VPN SETUP ==================
echo "${CYAN_TEXT}${BOLD_TEXT}🔐 Creating VPN Gateways...${RESET_FORMAT}"
gcloud compute target-vpn-gateways create on-prem-gw1 --network on-prem --region $REGION
gcloud compute target-vpn-gateways create cloud-gw1 --network cloud --region $REGION_1

echo "${CYAN_TEXT}${BOLD_TEXT}📌 Reserving Static IPs...${RESET_FORMAT}"
gcloud compute addresses create cloud-gw1 --region $REGION_1
gcloud compute addresses create on-prem-gw1 --region $REGION

cloud_gw1_ip=$(gcloud compute addresses describe cloud-gw1 --region $REGION_1 --format='value(address)')
on_prem_gw_ip=$(gcloud compute addresses describe on-prem-gw1 --region $REGION --format='value(address)')

echo "${CYAN_TEXT}${BOLD_TEXT}➡️ Creating Forwarding Rules...${RESET_FORMAT}"
gcloud compute forwarding-rules create cloud-1-fr-esp --ip-protocol ESP \
  --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region $REGION_1

gcloud compute forwarding-rules create cloud-1-fr-udp500 --ip-protocol UDP \
  --ports 500 --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region $REGION_1

gcloud compute forwarding-rules create cloud-fr-1-udp4500 --ip-protocol UDP \
  --ports 4500 --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region $REGION_1

gcloud compute forwarding-rules create on-prem-fr-esp --ip-protocol ESP \
  --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region $REGION

gcloud compute forwarding-rules create on-prem-fr-udp500 --ip-protocol UDP \
  --ports 500 --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region $REGION

gcloud compute forwarding-rules create on-prem-fr-udp4500 --ip-protocol UDP \
  --ports 4500 --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region $REGION

# ================== VPN TUNNELS ==================
echo "${ORANGE_TEXT}${BOLD_TEXT}🔗 Establishing VPN Tunnels...${RESET_FORMAT}"
gcloud compute vpn-tunnels create on-prem-tunnel1 --peer-address $cloud_gw1_ip \
  --target-vpn-gateway on-prem-gw1 --ike-version 2 \
  --local-traffic-selector 0.0.0.0/0 --remote-traffic-selector 0.0.0.0/0 \
  --shared-secret=[MY_SECRET] --region $REGION

gcloud compute vpn-tunnels create cloud-tunnel1 --peer-address $on_prem_gw_ip \
  --target-vpn-gateway cloud-gw1 --ike-version 2 \
  --local-traffic-selector 0.0.0.0/0 --remote-traffic-selector 0.0.0.0/0 \
  --shared-secret=[MY_SECRET] --region $REGION_1

# ================== ROUTES ==================
echo "${GREEN_TEXT}${BOLD_TEXT}🛣️ Creating VPN Routes...${RESET_FORMAT}"
gcloud compute routes create on-prem-route1 --destination-range 10.0.1.0/24 \
  --network on-prem --next-hop-vpn-tunnel on-prem-tunnel1 \
  --next-hop-vpn-tunnel-region $REGION

gcloud compute routes create cloud-route1 --destination-range 192.168.1.0/24 \
  --network cloud --next-hop-vpn-tunnel cloud-tunnel1 \
  --next-hop-vpn-tunnel-region $REGION_1

# ================== FINAL SUCCESS BLOCK ==================
echo
echo "${GOLD_TEXT}${BOLD_TEXT}      LAB COMPLETED SUCCESSFULLY - NIKHIL VAGHELA        ${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo "${PURPLE_TEXT}${BOLD_TEXT}Don't forget to Like, Share & Subscribe 🚀${RESET_FORMAT}"
