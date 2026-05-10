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

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          🚀 WELCOME TO GOOGLE CLOUD — KenilithCloudX            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Step 1: Initialize project settings
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 1 ] ── Initializing project ID, zone, and region settings...${RESET_FORMAT}"
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export ZONE=$(gcloud config get-value compute/zone)
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Project ID : $PROJECT_ID${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Zone       : $ZONE | Region : $REGION${RESET_FORMAT}"
echo

# Step 2: Clone repository and setup
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 2 ] ── Cloning monolith-to-microservices repo and running setup...${RESET_FORMAT}"
cd ~
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd ~/monolith-to-microservices
./setup.sh
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Repository cloned and application setup completed.${RESET_FORMAT}"
echo

# Step 3: Enable services and create cluster
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 3 ] ── Enabling Container API and provisioning GKE cluster...${RESET_FORMAT}"
gcloud services enable container.googleapis.com --project=$PROJECT_ID
gcloud container clusters create fancy-cluster \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --num-nodes 3 \
  --machine-type=e2-standard-4
echo "${RED_TEXT}${BOLD_TEXT}  ➤ GKE cluster 'fancy-cluster' created with 3 nodes.${RESET_FORMAT}"
echo

# Step 4: Deploy monolith
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 4 ] ── Deploying monolith application to the cluster...${RESET_FORMAT}"
cd ~/monolith-to-microservices
./deploy-monolith.sh
sleep 30
MONOLITH_IP=$(kubectl get service monolith -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Monolith deployed successfully.${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Monolith IP : http://$MONOLITH_IP${RESET_FORMAT}"
echo

# Step 5: Build and deploy orders microservice
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 5 ] ── Building and deploying orders microservice...${RESET_FORMAT}"
cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${PROJECT_ID}/orders:1.0.0 .
kubectl create deployment orders --image=gcr.io/${PROJECT_ID}/orders:1.0.0
kubectl expose deployment orders --type=LoadBalancer --port 80 --target-port 8081
sleep 45
ORDERS_IP=$(kubectl get service orders -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Orders microservice deployed successfully.${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Orders IP : http://$ORDERS_IP${RESET_FORMAT}"
echo

# Step 6: Update monolith with orders endpoint
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 6 ] ── Updating monolith config to point to orders microservice...${RESET_FORMAT}"
cat > ~/monolith-to-microservices/.env.monolith <<EOF
REACT_APP_ORDERS_URL=http://$ORDERS_IP/api/orders
REACT_APP_PRODUCTS_URL=/service/products
EOF
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/monolith:2.0.0 .
kubectl set image deployment/monolith monolith=gcr.io/${PROJECT_ID}/monolith:2.0.0
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Monolith updated to v2.0.0 with orders endpoint configured.${RESET_FORMAT}"
echo

# Step 7: Build and deploy products microservice
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 7 ] ── Building and deploying products microservice...${RESET_FORMAT}"
cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${PROJECT_ID}/products:1.0.0 .
kubectl create deployment products --image=gcr.io/${PROJECT_ID}/products:1.0.0
kubectl expose deployment products --type=LoadBalancer --port 80 --target-port 8082
sleep 30
PRODUCTS_IP=$(kubectl get service products -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Products microservice deployed successfully.${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Products IP : http://$PRODUCTS_IP${RESET_FORMAT}"
echo

# Step 8: Final monolith update with all microservices
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 8 ] ── Finalizing monolith config with all microservice endpoints...${RESET_FORMAT}"
cat > ~/monolith-to-microservices/.env.monolith <<EOF
REACT_APP_ORDERS_URL=http://$ORDERS_IP/api/orders
REACT_APP_PRODUCTS_URL=http://$PRODUCTS_IP/api/products
EOF
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/monolith:3.0.0 .
kubectl set image deployment/monolith monolith=gcr.io/${PROJECT_ID}/monolith:3.0.0
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Monolith updated to v3.0.0 with all microservices integrated.${RESET_FORMAT}"
echo

# Step 9: Deploy frontend service
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 9 ] ── Building and deploying standalone frontend service...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
cp .env.monolith .env
npm run build
cd ~/monolith-to-microservices/microservices/src/frontend
gcloud builds submit --tag gcr.io/${PROJECT_ID}/frontend:1.0.0 .
kubectl create deployment frontend --image=gcr.io/${PROJECT_ID}/frontend:1.0.0
kubectl expose deployment frontend --type=LoadBalancer --port 80 --target-port 8080
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Frontend service built and deployed successfully.${RESET_FORMAT}"
echo

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          ✅  LAB COMPLETED — ALL TASKS DONE SUCCESSFULLY !      ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}  🙏 Thank you for practicing with KenilithCloudX${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  📢 Subscribe for more hands-on Google Cloud content:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}  ${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
