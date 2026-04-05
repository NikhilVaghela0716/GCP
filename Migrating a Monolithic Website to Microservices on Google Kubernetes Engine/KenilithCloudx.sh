#!/bin/bash
# Define color variables
RED=`tput setaf 1`
BLUE=`tput setaf 4`
BOLD=`tput bold`
RESET=`tput sgr0`

clear


# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}         🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀               ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo ""

# Initialize project settings
echo "${RED}${BOLD}[ STEP 1 ] Configuring Project Settings...${RESET}"
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export ZONE=$(gcloud config get-value compute/zone)
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION

echo "${BLUE}${BOLD}  --> Project ID : $PROJECT_ID${RESET}"
echo "${BLUE}${BOLD}  --> Zone       : $ZONE${RESET}"
echo "${BLUE}${BOLD}  --> Region     : $REGION${RESET}"
echo ""

# Clone repository and setup
echo "${RED}${BOLD}[ STEP 2 ] Setting Up Application...${RESET}"
cd ~
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd ~/monolith-to-microservices
./setup.sh
echo "${BLUE}${BOLD}  --> Application setup done.${RESET}"
echo ""

# Enable services and create cluster
echo "${RED}${BOLD}[ STEP 3 ] Configuring Kubernetes Cluster...${RESET}"
gcloud services enable container.googleapis.com --project=$PROJECT_ID
gcloud container clusters create fancy-cluster --project=$PROJECT_ID --zone=$ZONE --num-nodes 3 --machine-type=e2-standard-4
echo "${BLUE}${BOLD}  --> Kubernetes cluster created successfully.${RESET}"
echo ""

# Deploy monolith
echo "${RED}${BOLD}[ STEP 4 ] Deploying Monolith Application...${RESET}"
cd ~/monolith-to-microservices
./deploy-monolith.sh
sleep 30
MONOLITH_IP=$(kubectl get service monolith -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${BLUE}${BOLD}  --> Monolith running at : http://$MONOLITH_IP${RESET}"
echo ""

# Build and deploy orders microservice
echo "${RED}${BOLD}[ STEP 5 ] Deploying Orders Microservice...${RESET}"
cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${PROJECT_ID}/orders:1.0.0 .
kubectl create deployment orders --image=gcr.io/${PROJECT_ID}/orders:1.0.0
kubectl expose deployment orders --type=LoadBalancer --port 80 --target-port 8081
sleep 45
ORDERS_IP=$(kubectl get service orders -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${BLUE}${BOLD}  --> Orders service running at : http://$ORDERS_IP${RESET}"
echo ""

# Update monolith configuration
echo "${RED}${BOLD}[ STEP 6 ] Updating Monolith Configuration...${RESET}"
cat > ~/monolith-to-microservices/.env.monolith <<EOF
REACT_APP_ORDERS_URL=http://$ORDERS_IP/api/orders
REACT_APP_PRODUCTS_URL=/service/products
EOF

cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/monolith:2.0.0 .
kubectl set image deployment/monolith monolith=gcr.io/${PROJECT_ID}/monolith:2.0.0
echo "${BLUE}${BOLD}  --> Monolith updated to version 2.0.0${RESET}"
echo ""

# Build and deploy products microservice
echo "${RED}${BOLD}[ STEP 7 ] Deploying Products Microservice...${RESET}"
cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${PROJECT_ID}/products:1.0.0 .
kubectl create deployment products --image=gcr.io/${PROJECT_ID}/products:1.0.0
kubectl expose deployment products --type=LoadBalancer --port 80 --target-port 8082
sleep 30
PRODUCTS_IP=$(kubectl get service products -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${BLUE}${BOLD}  --> Products service running at : http://$PRODUCTS_IP${RESET}"
echo ""

# Final monolith update
echo "${RED}${BOLD}[ STEP 8 ] Finalizing Microservices Integration...${RESET}"
cat > ~/monolith-to-microservices/.env.monolith <<EOF
REACT_APP_ORDERS_URL=http://$ORDERS_IP/api/orders
REACT_APP_PRODUCTS_URL=http://$PRODUCTS_IP/api/products
EOF

cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/monolith:3.0.0 .
kubectl set image deployment/monolith monolith=gcr.io/${PROJECT_ID}/monolith:3.0.0
echo "${BLUE}${BOLD}  --> Monolith updated to version 3.0.0${RESET}"
echo ""

# Deploy frontend
echo "${RED}${BOLD}[ STEP 9 ] Deploying Frontend Service...${RESET}"
cd ~/monolith-to-microservices/react-app
cp .env.monolith .env
npm run build

cd ~/monolith-to-microservices/microservices/src/frontend
gcloud builds submit --tag gcr.io/${PROJECT_ID}/frontend:1.0.0 .
kubectl create deployment frontend --image=gcr.io/${PROJECT_ID}/frontend:1.0.0
kubectl expose deployment frontend --type=LoadBalancer --port 80 --target-port 8080
echo "${BLUE}${BOLD}  --> Frontend service deployed successfully.${RESET}"
echo ""

# =========================
# COMPLETION FOOTER
# =========================
echo "${RED}${BOLD}==================================================================${RESET}"
echo "${RED}${BOLD}                  LAB COMPLETED SUCCESSFULLY !                   ${RESET}"
echo "${RED}${BOLD}==================================================================${RESET}"
echo ""
echo "${BLUE}${BOLD}  Thanks for learning with Kenilith Cloudx${RESET}"
echo "${RED}${BOLD}  Subscribe for more Google Cloud Labs :${RESET}"
echo "${BLUE}${BOLD}  https://www.youtube.com/@KenilithCloudx${RESET}"
echo ""
