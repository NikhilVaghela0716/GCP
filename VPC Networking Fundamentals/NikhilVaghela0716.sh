#!/bin/bash

# =========================
# COLOR DEFINITIONS (ONLY RED & BLUE)
# =========================
BLUE_TEXT=$(tput setaf 4)
RED_TEXT=$(tput setaf 1)
BOLD_TEXT=$(tput bold)
RESET_FORMAT=$(tput sgr0)

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# =========================
# USER INPUT
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}Enter a Second GCP zone:${RESET_FORMAT}"
read -r ZONE_2
echo "${BLUE_TEXT}You entered: ${BOLD_TEXT}$ZONE_2${RESET_FORMAT}"
echo

# Get default zone
export ZONE_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# =========================
# CREATE NETWORK
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating VPC Network...${RESET_FORMAT}"

gcloud compute networks create mynetwork \
  --project=$DEVSHELL_PROJECT_ID \
  --subnet-mode=auto \
  --mtu=1460 \
  --bgp-routing-mode=regional

echo "${RED_TEXT}Network creation completed.${RESET_FORMAT}"
echo

# =========================
# CREATE FIRST VM
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating first VM in zone: $ZONE_1${RESET_FORMAT}"

gcloud compute instances create mynet-us-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE_1 \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork \
  --metadata=enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --create-disk=auto-delete=yes,boot=yes,device-name=mynet-us-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE_1/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

echo "${RED_TEXT}First VM created successfully.${RESET_FORMAT}"
echo

# =========================
# CREATE SECOND VM
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}Creating second VM in zone: $ZONE_2${RESET_FORMAT}"

gcloud compute instances create mynet-second-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE_2 \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork \
  --metadata=enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --create-disk=auto-delete=yes,boot=yes,device-name=mynet-second-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE_2/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

echo "${RED_TEXT}Second VM created successfully.${RESET_FORMAT}"

# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
