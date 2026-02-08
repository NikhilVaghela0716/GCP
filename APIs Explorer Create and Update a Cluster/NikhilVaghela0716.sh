#!/bin/bash

# =========================
# COLOR DEFINITIONS
# =========================
BLUE_TEXT=$(tput setaf 4)
RED_TEXT=$(tput setaf 1)
BOLD_TEXT=$(tput bold)
RESET_FORMAT=$(tput sgr0)

# =========================
# CONFIGURATION VARIABLES
# =========================
CLUSTER_NAME="my-cluster"
PROJECT_ID=$DEVSHELL_PROJECT_ID

clear

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

echo "${BLUE_TEXT}${BOLD_TEXT}Initializing Zone and Region configuration...${RESET_FORMAT}"

# Fetch Zone and derive Region automatically
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(echo $ZONE | sed 's/-[a-z]$//')

echo "${BLUE_TEXT}Target Zone: ${ZONE}${RESET_FORMAT}"
echo "${BLUE_TEXT}Target Region: ${REGION}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Enabling Google Cloud Dataproc API...${RESET_FORMAT}"
gcloud services enable dataproc.googleapis.com
echo "${RED_TEXT}API Enabled successfully.${RESET_FORMAT}"
echo

# FIX: Add delay to allow API to propagate
echo "${BLUE_TEXT}${BOLD_TEXT}Waiting 30 seconds for API propagation...${RESET_FORMAT}"
sleep 30

# FIX: Grant Dataproc Worker role to default Service Account
echo "${BLUE_TEXT}${BOLD_TEXT}Granting IAM permissions to Service Account...${RESET_FORMAT}"
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role=roles/dataproc.worker \
    --quiet

echo "${RED_TEXT}Permissions granted.${RESET_FORMAT}"
echo

# =========================
# CLUSTER DEPLOYMENT
# =========================

echo "${RED_TEXT}${BOLD_TEXT}Provisioning Dataproc Cluster: ${CLUSTER_NAME}...${RESET_FORMAT}"
echo "${BLUE_TEXT}Note: This operation creates VM instances and may take time.${RESET_FORMAT}"

gcloud dataproc clusters create $CLUSTER_NAME \
    --region=$REGION \
    --zone=$ZONE \
    --image-version=2.0-debian10 \
    --optional-components=JUPYTER \
    --project=$PROJECT_ID \
    --quiet

echo "${RED_TEXT}Cluster provisioning complete.${RESET_FORMAT}"
echo

# =========================
# JOB EXECUTION
# =========================

echo "${BLUE_TEXT}${BOLD_TEXT}Submitting SparkPi Job to cluster...${RESET_FORMAT}"

gcloud dataproc jobs submit spark \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
    --class=org.apache.spark.examples.SparkPi \
    --project=$PROJECT_ID \
    -- \
    1000

echo "${RED_TEXT}Spark Job finished successfully.${RESET_FORMAT}"
echo

# =========================
# SCALING OPERATIONS
# =========================

echo "${BLUE_TEXT}${BOLD_TEXT}Updating cluster configuration (Scaling to 3 workers)...${RESET_FORMAT}"

gcloud dataproc clusters update $CLUSTER_NAME \
    --region=$REGION \
    --num-workers=3 \
    --project=$PROJECT_ID \
    --quiet

echo "${RED_TEXT}Scaling operation complete.${RESET_FORMAT}"
echo

# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
