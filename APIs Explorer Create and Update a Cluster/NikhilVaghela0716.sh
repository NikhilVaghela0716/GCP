#!/bin/bash

# =========================
# COLOR DEFINITIONS
# =========================
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# =========================
# CONFIGURATION VARIABLES
# =========================
CLUSTER_NAME="my-cluster"
PROJECT_ID=$DEVSHELL_PROJECT_ID

clear

# =========================
# HEADER
# =========================
# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# =========================
# INFRASTRUCTURE SETUP
# =========================

echo "${BLUE}${BOLD}Initializing Zone and Region configuration...${RESET}"

# Fetch Zone and derive Region automatically
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(echo $ZONE | sed 's/-[a-z]$//')

echo "${BLUE}Target Zone: ${ZONE}${RESET}"
echo "${BLUE}Target Region: ${REGION}${RESET}"
echo

echo "${BLUE}${BOLD}Enabling Google Cloud Dataproc API...${RESET}"
gcloud services enable dataproc.googleapis.com
echo "${RED}API Enabled successfully.${RESET}"
echo

# =========================
# CLUSTER DEPLOYMENT
# =========================

echo "${RED}${BOLD}Provisioning Dataproc Cluster: ${CLUSTER_NAME}...${RESET}"
echo "${BLUE}Note: This operation creates VM instances and may take time.${RESET}"

gcloud dataproc clusters create $CLUSTER_NAME \
    --region=$REGION \
    --zone=$ZONE \
    --image-version=2.0-debian10 \
    --optional-components=JUPYTER \
    --project=$PROJECT_ID \
    --quiet

echo "${RED}Cluster provisioning complete.${RESET}"
echo

# =========================
# JOB EXECUTION
# =========================

echo "${BLUE}${BOLD}Submitting SparkPi Job to cluster...${RESET}"

gcloud dataproc jobs submit spark \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
    --class=org.apache.spark.examples.SparkPi \
    --project=$PROJECT_ID \
    -- \
    1000

echo "${RED}Spark Job finished successfully.${RESET}"
echo

# =========================
# SCALING OPERATIONS
# =========================

echo "${BLUE}${BOLD}Updating cluster configuration (Scaling to 3 workers)...${RESET}"

gcloud dataproc clusters update $CLUSTER_NAME \
    --region=$REGION \
    --num-workers=3 \
    --project=$PROJECT_ID \
    --quiet

echo "${RED}Scaling operation complete.${RESET}"
echo

# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}         ✅ LAB COMPLETED SUCCESSFULLY!                       ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
