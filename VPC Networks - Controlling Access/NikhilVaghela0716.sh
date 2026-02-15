#!/bin/bash
# Define color variables (ONLY RED & BLUE)

RED=`tput setaf 1`
BLUE=`tput setaf 4`

BOLD=`tput bold`
RESET=`tput sgr0`


# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}              🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀            ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo

# Ask for zone input
echo "${RED}${BOLD}Please enter the zone value to export :${RESET}"
read ZONE
export ZONE

# Create instances
gcloud compute instances create blue --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --tags=web-server,http-server --create-disk=auto-delete=yes,boot=yes,device-name=blue,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

gcloud compute instances create green --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --create-disk=auto-delete=yes,boot=yes,device-name=blue,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

# Create firewall rule
gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create allow-http-web-server --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80,icmp --source-ranges=0.0.0.0/0 --target-tags=web-server

# Create test VM
gcloud compute instances create test-vm --machine-type=f1-micro --subnet=default --zone=$ZONE

# Create service account and grant permissions
gcloud iam service-accounts create network-admin --description="Service account for Network Admin role" --display-name="Network-admin"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=roles/compute.networkAdmin

gcloud iam service-accounts keys create credentials.json --iam-account=network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com

# Create and copy blue server setup script
cat > bluessh.sh <<'EOF_END'
sudo apt-get install nginx-light -y
sudo sed -i "14c\<h1>Welcome to the blue server!</h1>" /var/www/html/index.nginx-debian.html
EOF_END

gcloud compute scp bluessh.sh blue:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
gcloud compute ssh blue --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/bluessh.sh" --ssh-flag="-o ConnectTimeout=60"

# Create and copy green server setup script
cat > greenssh.sh <<'EOF_END'
sudo apt-get install nginx-light -y
sudo sed -i "14c\<h1>Welcome to the green server!</h1>" /var/www/html/index.nginx-debian.html
EOF_END

gcloud compute scp greenssh.sh green:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
gcloud compute ssh green --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/greenssh.sh"

echo "${BLUE}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

echo
echo "${RED}${BOLD}==============================================================${RESET}"
echo "${RED}${BOLD}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET}"
echo "${RED}${BOLD}==============================================================${RESET}"
echo
echo "${BLUE}${BOLD}🙏 Thanks for learning with Nikhil Vaghela${RESET}"
echo "${RED}${BOLD}📢 Subscribe for more Google Cloud Labs:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@Nikhil-Vaghela0716${RESET}"
echo

# Clean up temporary files
rm -f bluessh.sh greenssh.sh
