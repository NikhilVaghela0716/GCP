#!/bin/bash

# Color Definitions
BOLD=$(tput bold)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                🚀 GOOGLE CLOUD  | KenilithCloudX                ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${BLUE}${BOLD}  ▶  Starting deployment...${RESET}"
echo

# Section 1: Initial Setup
echo "${RED}${BOLD}  ◆  INITIAL SETUP${RESET}"
echo "${BLUE}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
echo "${BLUE}${BOLD}  ●  Checking authentication and region...${RESET}"
gcloud auth list
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${BLUE}${BOLD}  ✔  Region set to: ${RED}${REGION}${RESET}"
echo

# Section 2: Clone Repository
echo "${RED}${BOLD}  ◆  CLONING REPOSITORY${RESET}"
echo "${BLUE}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
echo "${BLUE}${BOLD}  ●  Cloning monolith-to-microservices repository...${RESET}"
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd ~/monolith-to-microservices
echo "${BLUE}${BOLD}  ●  Running setup script...${RESET}"
./setup.sh
echo "${BLUE}${BOLD}  ✔  Repository cloned and setup complete.${RESET}"
echo

# Section 3: Artifact Registry Setup
echo "${RED}${BOLD}  ◆  ARTIFACT REGISTRY SETUP${RESET}"
echo "${BLUE}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
cd ~/monolith-to-microservices/monolith
echo "${BLUE}${BOLD}  ●  Creating Artifact Registry repository...${RESET}"
gcloud artifacts repositories create monolith-demo \
    --location=$REGION \
    --repository-format=docker \
    --description="Docker repository for monolith demo"
echo "${BLUE}${BOLD}  ●  Configuring Docker authentication...${RESET}"
gcloud auth configure-docker $REGION-docker.pkg.dev
echo "${BLUE}${BOLD}  ✔  Artifact Registry setup complete.${RESET}"
echo

# Section 4: Enable Services
echo "${RED}${BOLD}  ◆  ENABLING GCP SERVICES${RESET}"
echo "${BLUE}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
echo "${BLUE}${BOLD}  ●  Enabling required GCP services:${RESET}"
echo "${BLUE}     •  artifactregistry.googleapis.com${RESET}"
echo "${BLUE}     •  cloudbuild.googleapis.com${RESET}"
echo "${BLUE}     •  run.googleapis.com${RESET}"
gcloud services enable artifactregistry.googleapis.com \
    cloudbuild.googleapis.com \
    run.googleapis.com
echo "${BLUE}${BOLD}  ✔  All services enabled successfully.${RESET}"
echo

# Section 5: Initial Build and Deploy
echo "${RED}${BOLD}  ◆  INITIAL BUILD AND DEPLOY${RESET}"
echo "${BLUE}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
echo "${BLUE}${BOLD}  ●  Building and submitting monolith image ${RED}(v1.0.0)${RESET}${BLUE}${BOLD}...${RESET}"
gcloud builds submit --tag $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0
echo
echo "${BLUE}${BOLD}  ●  Deploying monolith to Cloud Run...${RESET}"
gcloud run deploy monolith \
    --image $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0 \
    --allow-unauthenticated \
    --region $REGION
echo "${BLUE}${BOLD}  ✔  Initial deployment complete.${RESET}"
echo

# Section 6: Concurrency Testing
echo "${RED}${BOLD}  ◆  CONCURRENCY TESTING${RESET}"
echo "${BLUE}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
echo "${BLUE}${BOLD}  ●  Deploying with concurrency=${RED}1${RESET}${BLUE}${BOLD}...${RESET}"
gcloud run deploy monolith \
    --image $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0 \
    --allow-unauthenticated \
    --region $REGION \
    --concurrency 1
echo
echo "${BLUE}${BOLD}  ●  Deploying with concurrency=${RED}80${RESET}${BLUE}${BOLD}...${RESET}"
gcloud run deploy monolith \
    --image $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0 \
    --allow-unauthenticated \
    --region $REGION \
    --concurrency 80
echo "${BLUE}${BOLD}  ✔  Concurrency testing complete.${RESET}"
echo

# Section 7: Frontend Update
echo "${RED}${BOLD}  ◆  FRONTEND UPDATE${RESET}"
echo "${BLUE}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
echo "${BLUE}${BOLD}  ●  Updating frontend code...${RESET}"
cd ~/monolith-to-microservices/react-app/src/pages/Home
mv index.js.new index.js
echo "${BLUE}${BOLD}  ✔  Frontend file updated. Current content:${RESET}"
echo "${RED}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
cat ~/monolith-to-microservices/react-app/src/pages/Home/index.js
echo "${RED}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

# Section 8: Rebuild and Redeploy
echo "${RED}${BOLD}  ◆  REBUILD AND REDEPLOY${RESET}"
echo "${BLUE}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
echo "${BLUE}${BOLD}  ●  Building monolith with updated frontend...${RESET}"
cd ~/monolith-to-microservices/react-app
npm run build:monolith
echo
echo "${BLUE}${BOLD}  ●  Building and submitting monolith image ${RED}(v2.0.0)${RESET}${BLUE}${BOLD}...${RESET}"
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:2.0.0
echo
echo "${BLUE}${BOLD}  ●  Deploying updated monolith to Cloud Run...${RESET}"
gcloud run deploy monolith \
    --image $REGION-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:2.0.0 \
    --allow-unauthenticated \
    --region $REGION
echo "${BLUE}${BOLD}  ✔  Redeploy complete.${RESET}"
echo

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}                LAB COMPLETED SUCCESSFULLY!                   ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}${BOLD_TEXT}🙏 Thanks for learning with KenilithCloudX${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
