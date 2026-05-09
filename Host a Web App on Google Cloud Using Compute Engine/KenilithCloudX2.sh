#!/bin/bash

# ==============================
# COLORS & FORMATTING
# ==============================
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          🚀 WELCOME TO GOOGLE CLOUD — KenilithCloudX            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 1 ] ── Configuring compute zone and region from environment...${RESET_FORMAT}"
export REGION="${ZONE%-*}"
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Zone: $ZONE | Region: $REGION configured.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 2 ] ── Fetching existing forwarding rules from load balancer...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app/
gcloud compute forwarding-rules list --global
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 3 ] ── Retrieving external IP of the fancy-http-rule forwarding rule...${RESET_FORMAT}"
export EXTERNAL_IP_FANCY=$(gcloud compute forwarding-rules describe fancy-http-rule --global --format='get(IPAddress)')
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Load Balancer External IP : $EXTERNAL_IP_FANCY${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 4 ] ── Writing React app environment config with load balancer endpoints...${RESET_FORMAT}"
cat > .env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_BACKEND:8081/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_BACKEND:8082/api/products

REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_FANCY/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_FANCY/api/products
EOF
echo "${RED_TEXT}${BOLD_TEXT}  ➤ .env file updated with load balancer IP endpoints.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 5 ] ── Installing dependencies and rebuilding the React application...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
npm install && npm run-script build
echo "${RED_TEXT}${BOLD_TEXT}  ➤ React application built successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 6 ] ── Syncing updated build artifacts to Cloud Storage bucket...${RESET_FORMAT}"
cd ~
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Build artifacts uploaded to GCS bucket.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 7 ] ── Triggering rolling replacement on frontend managed instance group...${RESET_FORMAT}"
gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
    --zone=$ZONE \
    --max-unavailable 100%
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Rolling replacement initiated for fancy-fe-mig.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 8 ] ── Enabling autoscaling on frontend and backend instance groups...${RESET_FORMAT}"
gcloud compute instance-groups managed set-autoscaling \
  fancy-fe-mig \
  --zone=$ZONE \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

gcloud compute instance-groups managed set-autoscaling \
  fancy-be-mig \
  --zone=$ZONE \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Autoscaling set to max 2 replicas at 60% LB utilization for both MIGs.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 9 ] ── Enabling Cloud CDN on the frontend backend service...${RESET_FORMAT}"
gcloud compute backend-services update fancy-fe-frontend \
    --enable-cdn --global
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Cloud CDN enabled on fancy-fe-frontend backend service.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 10 ] ── Resizing frontend instance to e2-small machine type...${RESET_FORMAT}"
gcloud compute instances set-machine-type frontend \
  --zone=$ZONE \
  --machine-type e2-small
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Frontend instance machine type updated to e2-small.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 11 ] ── Creating new frontend instance template from updated instance...${RESET_FORMAT}"
gcloud compute instance-templates create fancy-fe-new \
    --region=$REGION \
    --source-instance=frontend \
    --source-instance-zone=$ZONE
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Instance template 'fancy-fe-new' created successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 12 ] ── Applying new template via rolling update to frontend MIG...${RESET_FORMAT}"
gcloud compute instance-groups managed rolling-action start-update fancy-fe-mig \
  --zone=$ZONE \
  --version template=fancy-fe-new
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Rolling update started with template 'fancy-fe-new'.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 13 ] ── Updating React homepage with new index.js file...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app/src/pages/Home
mv index.js.new index.js
cat ~/monolith-to-microservices/react-app/src/pages/Home/index.js
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Homepage index.js replaced with updated version.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 14 ] ── Rebuilding React application with updated homepage...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
npm install && npm run-script build
echo "${RED_TEXT}${BOLD_TEXT}  ➤ React application rebuilt with new homepage.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 15 ] ── Uploading final build to Cloud Storage and triggering redeployment...${RESET_FORMAT}"
cd ~
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/
gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
  --zone=$ZONE \
  --max-unavailable=100%
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Final build uploaded and rolling replacement triggered.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 16 ] ── Cleaning up temporary lab script files...${RESET_FORMAT}"
FILE="TechCode1.sh"
if [ -f "$FILE" ]; then
  rm "$FILE"
  echo "${RED_TEXT}${BOLD_TEXT}  ➤ $FILE removed successfully.${RESET_FORMAT}"
else
  echo "${RED_TEXT}${BOLD_TEXT}  ➤ $FILE not found, skipping.${RESET_FORMAT}"
fi

FILE="TechCode2.sh"
if [ -f "$FILE" ]; then
  rm "$FILE"
  echo "${RED_TEXT}${BOLD_TEXT}  ➤ $FILE removed successfully.${RESET_FORMAT}"
else
  echo "${RED_TEXT}${BOLD_TEXT}  ➤ $FILE not found, skipping.${RESET_FORMAT}"
fi
echo

echo "${BLUE_TEXT}${BOLD_TEXT}  🌐 Load Balancer IP : ${RESET_FORMAT}${RED_TEXT}${BOLD_TEXT}$EXTERNAL_IP_FANCY${RESET_FORMAT}"
echo

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}        ✅ LAB COMPLETED SUCCESSFULLY!                        ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}  🙏 Thank you for practicing with KenilithCloudX${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  📢 Subscribe for more hands-on Google Cloud content:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}  ${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
