#!/bin/bash
# Define color variables
RED=`tput setaf 1`
BLUE=`tput setaf 4`

BG_RED=`tput setab 1`
BG_BLUE=`tput setab 4`

BOLD=`tput bold`
RESET=`tput sgr0`

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}           🚀 Initiating Deployment | Kenilith Cloudx 🚀         ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo

# Initialize project settings
echo "${BLUE}${BOLD}--> Fetching Environment Variables${RESET}"
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export ZONE=$(gcloud config get-value compute/zone)
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION

echo "${RED}==> Active Project: $PROJECT_ID${RESET}"
echo "${RED}==> Active Zone: $ZONE | Active Region: $REGION${RESET}"
echo

# Clone repository and setup
echo "${BLUE}${BOLD}--> Downloading and Preparing Repository${RESET}"
cd ~
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd ~/monolith-to-microservices
./setup.sh
echo "${RED}==> Repository setup is done${RESET}"
echo

# Enable services and create cluster
echo "${BLUE}${BOLD}--> Provisioning GKE Cluster (This may take a moment)${RESET}"
gcloud services enable container.googleapis.com --project=$PROJECT_ID
gcloud container clusters create fancy-cluster --project=$PROJECT_ID --zone=$ZONE --num-nodes 3 --machine-type=e2-standard-4
echo "${RED}==> Cluster creation successful${RESET}"
echo

# Deploy monolith
echo "${BLUE}${BOLD}--> Rolling out Monolith App${RESET}"
cd ~/monolith-to-microservices
./deploy-monolith.sh
sleep 30
MONOLITH_IP=$(kubectl get service monolith -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${RED}==> Monolith is live at: http://$MONOLITH_IP${RESET}"
echo

# Build and deploy orders microservice
echo "${BLUE}${BOLD}--> Building & Deploying Orders Service${RESET}"
cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${PROJECT_ID}/orders:1.0.0 .
kubectl create deployment orders --image=gcr.io/${PROJECT_ID}/orders:1.0.0
kubectl expose deployment orders --type=LoadBalancer --port 80 --target-port 8081
sleep 45
ORDERS_IP=$(kubectl get service orders -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${RED}==> Orders service is live at: http://$ORDERS_IP${RESET}"
echo

# Update monolith configuration
echo "${BLUE}${BOLD}--> Reconfiguring Monolith to use Orders${RESET}"
cat > ~/monolith-to-microservices/.env.monolith <<EOF
REACT_APP_ORDERS_URL=http://$ORDERS_IP/api/orders
REACT_APP_PRODUCTS_URL=/service/products
EOF

cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/monolith:2.0.0 .
kubectl set image deployment/monolith monolith=gcr.io/${PROJECT_ID}/monolith:2.0.0
echo "${RED}==> Monolith successfully upgraded to v2.0.0${RESET}"
echo

# Build and deploy products microservice
echo "${BLUE}${BOLD}--> Building & Deploying Products Service${RESET}"
cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${PROJECT_ID}/products:1.0.0 .
kubectl create deployment products --image=gcr.io/${PROJECT_ID}/products:1.0.0
kubectl expose deployment products --type=LoadBalancer --port 80 --target-port 8082
sleep 30
PRODUCTS_IP=$(kubectl get service products -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${RED}==> Products service is live at: http://$PRODUCTS_IP${RESET}"
echo

# Final monolith update
echo "${BLUE}${BOLD}--> Reconfiguring Monolith to use Products${RESET}"
cat > ~/monolith-to-microservices/.env.monolith <<EOF
REACT_APP_ORDERS_URL=http://$ORDERS_IP/api/orders
REACT_APP_PRODUCTS_URL=http://$PRODUCTS_IP/api/products
EOF

cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/monolith:3.0.0 .
kubectl set image deployment/monolith monolith=gcr.io/${PROJECT_ID}/monolith:3.0.0
echo "${RED}==> Monolith successfully upgraded to v3.0.0${RESET}"
echo

# Deploy frontend
echo "${BLUE}${BOLD}--> Spinning up Frontend Application${RESET}"
cd ~/monolith-to-microservices/react-app
cp .env.monolith .env
npm run build

cd ~/monolith-to-microservices/microservices/src/frontend
gcloud builds submit --tag gcr.io/${PROJECT_ID}/frontend:1.0.0 .
kubectl create deployment frontend --image=gcr.io/${PROJECT_ID}/frontend:1.0.0
kubectl expose deployment frontend --type=LoadBalancer --port 80 --target-port 8080
echo "${RED}==> Frontend deployment finished${RESET}"
echo

# ===================== FINAL BRANDING =====================
# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED}${BOLD}==============================================================${RESET}"
echo "${RED}${BOLD}                 ✅ ALL TASKS COMPLETED!                      ${RESET}"
echo "${RED}${BOLD}==============================================================${RESET}"
echo
echo "${BLUE}${BOLD}Thank you for following along with Kenilith Cloudx${RESET}"
echo "${RED}${BOLD}Catch more tutorials on our channel:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@KenilithCloudx${RESET}"
echo
