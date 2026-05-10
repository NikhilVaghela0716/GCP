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

# =========================
# USER INPUT
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}[ INPUT ] ── Please provide the required configuration values:${RESET_FORMAT}"
echo
read -p "$(echo "${RED_TEXT}${BOLD_TEXT}  ➤ Enter your zone        (e.g., us-central1-a) : ${RESET_FORMAT}")" ZONE
read -p "$(echo "${RED_TEXT}${BOLD_TEXT}  ➤ Enter monolith identifier    (e.g., monolith) : ${RESET_FORMAT}")" MON_IDENT
read -p "$(echo "${RED_TEXT}${BOLD_TEXT}  ➤ Enter cluster name   (e.g., fancy-cluster)   : ${RESET_FORMAT}")" CLUSTER
read -p "$(echo "${RED_TEXT}${BOLD_TEXT}  ➤ Enter orders identifier       (e.g., orders) : ${RESET_FORMAT}")" ORD_IDENT
read -p "$(echo "${RED_TEXT}${BOLD_TEXT}  ➤ Enter products identifier   (e.g., products) : ${RESET_FORMAT}")" PROD_IDENT
read -p "$(echo "${RED_TEXT}${BOLD_TEXT}  ➤ Enter frontend identifier   (e.g., frontend) : ${RESET_FORMAT}")" FRONT_IDENT

# Export variables
export ZONE
export MON_IDENT
export CLUSTER
export ORD_IDENT
export PROD_IDENT
export FRONT_IDENT
export PROJECT_ID=$(gcloud config get-value project)

echo
echo "${BLUE_TEXT}${BOLD_TEXT}[ CONFIG ] ── Configuration summary loaded successfully:${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Zone       : $ZONE${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Monolith   : $MON_IDENT${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Cluster    : $CLUSTER${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Orders     : $ORD_IDENT${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Products   : $PROD_IDENT${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Frontend   : $FRONT_IDENT${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Project ID : $PROJECT_ID${RESET_FORMAT}"
echo

# =========================
# STEP 1 — Project Settings
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 1 ] ── Configuring compute zone and enabling required APIs...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE
gcloud services enable cloudbuild.googleapis.com container.googleapis.com
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Zone configured and Cloud Build + Container APIs enabled.${RESET_FORMAT}"
echo

# =========================
# STEP 2 — Clone & Setup
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 2 ] ── Cloning monolith-to-microservices repo and running setup...${RESET_FORMAT}"
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd ~/monolith-to-microservices
./setup.sh
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Repository cloned and application setup completed.${RESET_FORMAT}"
echo

# =========================
# STEP 3 — Deploy Monolith
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 3 ] ── Building monolith image, creating cluster, and deploying...${RESET_FORMAT}"
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${PROJECT_ID}/${MON_IDENT}:1.0.0 .
gcloud container clusters create $CLUSTER --num-nodes 3
kubectl create deployment $MON_IDENT --image=gcr.io/${PROJECT_ID}/$MON_IDENT:1.0.0
kubectl expose deployment $MON_IDENT --type=LoadBalancer --port 80 --target-port 8080
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Monolith v1.0.0 built, cluster '$CLUSTER' created, and service exposed.${RESET_FORMAT}"
echo

# =========================
# STEP 4 — Deploy Microservices
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 4 ] ── Building and deploying orders and products microservices...${RESET_FORMAT}"
cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${PROJECT_ID}/$ORD_IDENT:1.0.0 .

cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${PROJECT_ID}/$PROD_IDENT:1.0.0 .

kubectl create deployment $ORD_IDENT --image=gcr.io/${PROJECT_ID}/$ORD_IDENT:1.0.0
kubectl expose deployment $ORD_IDENT --type=LoadBalancer --port 80 --target-port 8081

kubectl create deployment $PROD_IDENT --image=gcr.io/${PROJECT_ID}/$PROD_IDENT:1.0.0
kubectl expose deployment $PROD_IDENT --type=LoadBalancer --port 80 --target-port 8082
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Orders (port 8081) and Products (port 8082) microservices deployed.${RESET_FORMAT}"
echo

# =========================
# STEP 5 — Deploy Frontend
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 5 ] ── Building and deploying the frontend service...${RESET_FORMAT}"
cd ~/monolith-to-microservices/microservices/src/frontend
gcloud builds submit --tag gcr.io/${PROJECT_ID}/$FRONT_IDENT:1.0.0 .
kubectl create deployment $FRONT_IDENT --image=gcr.io/${PROJECT_ID}/$FRONT_IDENT:1.0.0
kubectl expose deployment $FRONT_IDENT --type=LoadBalancer --port 80 --target-port 8080
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Frontend v1.0.0 built and deployed, service exposed on port 80.${RESET_FORMAT}"
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
