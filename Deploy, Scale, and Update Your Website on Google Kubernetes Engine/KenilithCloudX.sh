#!/bin/bash

# Color variables - Red and Blue only
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

# Step 1: List authenticated accounts
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 1 ] ── Fetching list of authenticated GCloud accounts...${RESET_FORMAT}"
gcloud auth list
echo -e "\n"

# Step 2: Set compute zone
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 2 ] ── Detecting and applying compute zone configuration...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud config set compute/zone $ZONE
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Active Zone : $ZONE${RESET_FORMAT}"
echo -e "\n"

# Step 3: Enable container API
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 3 ] ── Enabling Google Kubernetes Container API...${RESET_FORMAT}"
gcloud services enable container.googleapis.com
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Container API enabled successfully.${RESET_FORMAT}"
echo -e "\n"

# Step 4: Create GKE cluster
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 4 ] ── Provisioning GKE cluster 'fancy-cluster' with 3 nodes...${RESET_FORMAT}"
gcloud container clusters create fancy-cluster --num-nodes 3
echo "${RED_TEXT}${BOLD_TEXT}  ➤ GKE cluster creation complete.${RESET_FORMAT}"
echo -e "\n"

# Step 5: List instances
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 5 ] ── Retrieving all active compute instances in the project...${RESET_FORMAT}"
gcloud compute instances list
echo -e "\n"

# Step 6: Clone repository
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 6 ] ── Cloning monolith-to-microservices repository from GitHub...${RESET_FORMAT}"
cd ~
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Repository cloned to home directory.${RESET_FORMAT}"
echo -e "\n"

# Step 7: Run setup script
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 7 ] ── Running initial project setup script...${RESET_FORMAT}"
cd ~/monolith-to-microservices
./setup.sh
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Setup script execution finished.${RESET_FORMAT}"
echo -e "\n"

# Step 8: Install Node.js LTS
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 8 ] ── Installing Node.js LTS version via NVM...${RESET_FORMAT}"
nvm install --lts
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Node.js LTS installed successfully.${RESET_FORMAT}"
echo -e "\n"

# Step 9: Enable Cloud Build API
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 9 ] ── Activating Google Cloud Build API...${RESET_FORMAT}"
gcloud services enable cloudbuild.googleapis.com
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Cloud Build API is now active.${RESET_FORMAT}"
echo -e "\n"

# Step 10: Build and deploy monolith
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 10 ] ── Building monolith container image and deploying to GKE...${RESET_FORMAT}"
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:1.0.0 .
kubectl create deployment monolith --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:1.0.0
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Monolith v1.0.0 deployed to Kubernetes cluster.${RESET_FORMAT}"
echo -e "\n"

# Step 11: Verify deployment
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 11 ] ── Verifying all deployed Kubernetes resources...${RESET_FORMAT}"
kubectl get all
echo -e "\n"

# Step 12: Expose service
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 12 ] ── Exposing monolith deployment as a LoadBalancer service...${RESET_FORMAT}"
kubectl expose deployment monolith --type=LoadBalancer --port 80 --target-port 8080
kubectl get service
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Service exposed on port 80. Awaiting external IP assignment.${RESET_FORMAT}"
echo -e "\n"

# Step 13: Scale deployment
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 13 ] ── Scaling monolith deployment to 3 replicas...${RESET_FORMAT}"
kubectl scale deployment monolith --replicas=3
kubectl get all
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Deployment successfully scaled to 3 running replicas.${RESET_FORMAT}"
echo -e "\n"

# Step 14: Update React app
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 14 ] ── Applying updated homepage to the React application...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app/src/pages/Home
mv index.js.new index.js
cat ~/monolith-to-microservices/react-app/src/pages/Home/index.js
echo "${RED_TEXT}${BOLD_TEXT}  ➤ React homepage updated with new index.js file.${RESET_FORMAT}"
echo -e "\n"

# Step 15: Build React app
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 15 ] ── Compiling React app for monolith deployment...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
npm run build:monolith
echo "${RED_TEXT}${BOLD_TEXT}  ➤ React build completed and ready for packaging.${RESET_FORMAT}"
echo -e "\n"

# Step 16: Update monolith image
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 16 ] ── Building monolith v2.0.0 and rolling out updated image...${RESET_FORMAT}"
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:2.0.0 .
kubectl set image deployment/monolith monolith=gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:2.0.0
kubectl get pods
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Rolling update to monolith v2.0.0 applied successfully.${RESET_FORMAT}"
echo -e "\n"

# Final message
echo
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          ✅  ALL STEPS COMPLETED — LAB FINISHED!                ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}  🙏 Thank you for practicing with KenilithCloudX${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  📢 Subscribe for more hands-on Google Cloud content:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}  ${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
