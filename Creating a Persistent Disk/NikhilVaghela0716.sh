#!/bin/bash

# =========================
# COLOR DEFINITIONS
# =========================
RED=`tput setaf 1`
BLUE=`tput setaf 4`
BOLD=`tput bold`
RESET=`tput sgr0`

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}            🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀               ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo

read -p "${RED}${BOLD} Enter ZONE: ${RESET}" ZONE
export ZONE=$ZONE
export REGION="${ZONE%-*}"

echo "${BLUE}${BOLD}Setting the compute zone and region...${RESET}"
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

echo "${BLUE}${BOLD}Creating a compute instance 'gcelab'...${RESET}"
gcloud compute instances create gcelab --zone $ZONE --machine-type e2-standard-2

echo "${BLUE}${BOLD}Creating a disk 'mydisk' of 200GB...${RESET}"
gcloud compute disks create mydisk --size=200GB --zone $ZONE

echo "${BLUE}${BOLD}Attaching disk 'mydisk' to instance 'gcelab'...${RESET}"
gcloud compute instances attach-disk gcelab --disk mydisk --zone $ZONE

echo "${BLUE}${BOLD}Creating the 'prepare_disk.sh' script...${RESET}"
cat > prepare_disk.sh <<'EOF_END'
ls -l /dev/disk/by-id/
sudo mkdir -p /mnt/mydisk
sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1
sudo mount -o discard,defaults /dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1 /mnt/mydisk
EOF_END

echo "${BLUE}${BOLD}Transferring script 'prepare_disk.sh' to 'gcelab' instance...${RESET}"
gcloud compute scp prepare_disk.sh gcelab:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

echo "${BLUE}${BOLD}Executing the 'prepare_disk.sh' script on 'gcelab'...${RESET}"
gcloud compute ssh gcelab --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${RED}${BOLD}==============================================================${RESET}"
echo "${RED}${BOLD}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET}"
echo "${RED}${BOLD}==============================================================${RESET}"
echo
echo "${BLUE}${BOLD}🙏 Thanks for learning with Nikhil Vaghela${RESET}"
echo "${RED}${BOLD}📢 Subscribe for more Google Cloud Labs:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@Nikhil-Vaghela0716${RESET}"
echo
