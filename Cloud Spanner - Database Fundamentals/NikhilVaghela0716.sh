#!/bin/bash

# ================= COLOR DEFINITIONS =================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[1;31m'
GREEN_TEXT=$'\033[1;32m'
YELLOW_TEXT=$'\033[1;33m'
BLUE_TEXT=$'\033[1;34m'
MAGENTA_TEXT=$'\033[1;35m'
CYAN_TEXT=$'\033[1;36m'
WHITE_TEXT=$'\033[1;37m'
GOLD_TEXT=$'\033[38;5;220m'
PURPLE_TEXT=$'\033[38;5;141m'
TEAL_TEXT=$'\033[38;5;44m'

RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# ================= WELCOME =================
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}   🚀 Welcome to Cloud Spanner Banking Lab 🚀            ${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo -e "${CYAN_TEXT}${BOLD_TEXT}Initializing Google Cloud environment...${RESET_FORMAT}"
echo

# ================= AUTH =================
echo -e "${BLUE_TEXT}${BOLD_TEXT}🔐 Verifying gcloud authentication${RESET_FORMAT}"
gcloud auth list
echo

# ================= REGION & PROJECT =================
echo -e "${TEAL_TEXT}${BOLD_TEXT}📍 Fetching project configuration${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/region $REGION

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID
echo

echo -e "${GREEN_TEXT}${BOLD_TEXT}✔ Zone:${RESET_FORMAT} ${WHITE_TEXT}$ZONE${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}✔ Region:${RESET_FORMAT} ${WHITE_TEXT}$REGION${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}✔ Project:${RESET_FORMAT} ${WHITE_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo

# ================= SPANNER INSTANCE 1 =================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}🏦 Creating Cloud Spanner Instance: banking-instance${RESET_FORMAT}"
gcloud spanner instances create banking-instance --project=$DEVSHELL_PROJECT_ID \
  --config=regional-$REGION \
  --description="Cloud Spanner banking workload" \
  --nodes=1
echo

echo -e "${BLUE_TEXT}${BOLD_TEXT}📂 Creating database: banking-db${RESET_FORMAT}"
gcloud spanner databases create banking-db --instance=banking-instance
echo

echo -e "${MAGENTA_TEXT}${BOLD_TEXT}🧱 Creating Customer table${RESET_FORMAT}"
gcloud spanner databases ddl update banking-db \
  --instance=banking-instance \
  --ddl="CREATE TABLE Customer (
    CustomerId STRING(36) NOT NULL,
    Name STRING(MAX) NOT NULL,
    Location STRING(MAX) NOT NULL,
  ) PRIMARY KEY (CustomerId);"
echo

# ================= SPANNER INSTANCE 2 =================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}🏦 Creating Cloud Spanner Instance: banking-instance-2${RESET_FORMAT}"
gcloud spanner instances create banking-instance-2 --project=$DEVSHELL_PROJECT_ID \
  --config=regional-$REGION \
  --description="High availability banking workload" \
  --nodes=2
echo

echo -e "${BLUE_TEXT}${BOLD_TEXT}📂 Creating database: banking-db-2${RESET_FORMAT}"
gcloud spanner databases create banking-db-2 --instance=banking-instance-2
echo

# ================= FINAL MESSAGE =================
echo
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}      🎉 LAB COMPLETED SUCCESSFULLY 🎉                  ${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo -e "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo -e "${PURPLE_TEXT}${BOLD_TEXT}Subscribe for more Google Cloud Labs 🚀${RESET_FORMAT}"
