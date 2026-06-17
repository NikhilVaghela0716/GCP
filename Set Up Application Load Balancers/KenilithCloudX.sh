#!/bin/bash

# Define color variables
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Spinner function for visual feedback
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                  🚀 GOOGLE CLOUD LAB | KenilithCloudX            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

gcloud auth list

read -p "Enter Zone: " ZONE
export REGION=${ZONE%-*}

gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

echo
echo "${BLUE_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬▬ CREATING WEB SERVERS ▬▬▬▬▬▬▬▬▬${RESET_FORMAT}"

# Create www1
echo "${RED_TEXT}Creating www1...${RESET_FORMAT}"
gcloud compute instances create www1 \
    --zone=$ZONE \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "
<h3>Web Server: www1</h3>" | tee /var/www/html/index.html' &

pid=$!
spinner $pid
wait $pid
echo "${BLUE_TEXT}✓ www1 created successfully${RESET_FORMAT}"

# Create www2
echo "${RED_TEXT}Creating www2...${RESET_FORMAT}"
gcloud compute instances create www2 \
    --zone=$ZONE \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "
<h3>Web Server: www2</h3>" | tee /var/www/html/index.html' &

pid=$!
spinner $pid
wait $pid
echo "${BLUE_TEXT}✓ www2 created successfully${RESET_FORMAT}"

# Create www3
echo "${RED_TEXT}Creating www3...${RESET_FORMAT}"
gcloud compute instances create www3 \
    --zone=$ZONE  \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "
<h3>Web Server: www3</h3>" | tee /var/www/html/index.html' &

pid=$!
spinner $pid
wait $pid
echo "${BLUE_TEXT}✓ www3 created successfully${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬▬ CONFIGURING FIREWALL ▬▬▬▬▬▬▬▬▬${RESET_FORMAT}"

echo "${RED_TEXT}Creating firewall rule...${RESET_FORMAT}"
gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80 &

pid=$!
spinner $pid
wait $pid
echo "${BLUE_TEXT}✓ Firewall rule created${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬▬ VERIFYING INSTANCES ▬▬▬▬▬▬▬▬▬${RESET_FORMAT}"
gcloud compute instances list

echo
echo "${BLUE_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬▬ CREATING INSTANCE TEMPLATE ▬▬▬▬▬▬▬▬▬${RESET_FORMAT}"

echo "${RED_TEXT}Creating lb-backend-template...${RESET_FORMAT}"
gcloud compute instance-templates create lb-backend-template \
   --region=$REGION \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-11 \
   --image-project=debian-cloud \
   --metadata=startup-script='#!/bin/bash
     apt-get update
     apt-get install apache2 -y
     a2ensite default-ssl
     a2enmod ssl
     vm_hostname="$(curl -H "Metadata-Flavor:Google" \
     http://169.254.169.254/computeMetadata/v1/instance/name)"
     echo "Page served from: $vm_hostname" | \
     tee /var/www/html/index.html
     systemctl restart apache2' &

pid=$!
spinner $pid
wait $pid
echo "${BLUE_TEXT}✓ Instance template created${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬▬ CREATING MANAGED INSTANCE GROUP ▬▬▬▬▬▬▬▬▬${RESET_FORMAT}"

echo "${RED_TEXT}Creating lb-backend-group...${RESET_FORMAT}"
gcloud compute instance-groups managed create lb-backend-group \
   --template=lb-backend-template --size=2 --zone=$ZONE &

pid=$!
spinner $pid
wait $pid
echo "${BLUE_TEXT}✓ Managed instance group created${RESET_FORMAT}"

echo
echo "${RED_TEXT}Waiting for managed instances to start...${RESET_FORMAT}"
sleep 60

echo
echo "${BLUE_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬▬ CONFIGURING HEALTH CHECK FIREWALL ▬▬▬▬▬▬▬▬▬${RESET_FORMAT}"

echo "${RED_TEXT}Creating health check firewall rule...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80 &

pid=$!
spinner $pid
wait $pid
echo "${BLUE_TEXT}✓ Health check firewall rule created${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬▬ CONFIGURING LOAD BALANCER ▬▬▬▬▬▬▬▬▬${RESET_FORMAT}"

echo "${RED_TEXT}Reserving IP address...${RESET_FORMAT}"
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global &

pid=$!
spinner $pid
wait $pid

echo "${RED_TEXT}Retrieving IP address...${RESET_FORMAT}"
gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global

echo "${RED_TEXT}Creating health check...${RESET_FORMAT}"
gcloud compute health-checks create http http-basic-check \
  --port 80 &

pid=$!
spinner $pid
wait $pid

echo "${RED_TEXT}Creating backend service...${RESET_FORMAT}"
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global &

pid=$!
spinner $pid
wait $pid

echo "${RED_TEXT}Adding backend to service...${RESET_FORMAT}"
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=$ZONE \
  --global &

pid=$!
spinner $pid
wait $pid

echo "${RED_TEXT}Creating URL map...${RESET_FORMAT}"
gcloud compute url-maps create web-map-http \
    --default-service web-backend-service &

pid=$!
spinner $pid
wait $pid

echo "${RED_TEXT}Creating target HTTP proxy...${RESET_FORMAT}"
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http &

pid=$!
spinner $pid
wait $pid

echo "${RED_TEXT}Creating forwarding rule...${RESET_FORMAT}"
gcloud compute forwarding-rules create http-content-rule \
   --address=lb-ipv4-1 \
   --global \
   --target-http-proxy=http-lb-proxy \
   --ports=80 &

pid=$!
spinner $pid
wait $pid

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          		        ✅ LAB FINISHED!                        ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}🙏 Thank you for learning with KenilithCloudX!${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more hands-on Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
