#!/bin/bash

# ====================================================
# COLOR DEFINITIONS
# ====================================================
BLUE_TEXT=$(tput setaf 4)
RED_TEXT=$(tput setaf 1)
BOLD_TEXT=$(tput bold)
RESET_FORMAT=$(tput sgr0)

clear

# ====================================================
# WELCOME MESSAGE
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}      SECURITY COMMAND CENTER LAB | NIKHIL VAGHELA                ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ====================================================
# STEP 1: ENVIRONMENT SETUP
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 1: Configuring Environment Variables...${RESET_FORMAT}"

gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

echo "${BLUE_TEXT}Project ID: ${PROJECT_ID}${RESET_FORMAT}"
echo "${BLUE_TEXT}Region: ${REGION}${RESET_FORMAT}"
echo "${BLUE_TEXT}Zone: ${ZONE}${RESET_FORMAT}"
echo

# ====================================================
# STEP 2: ENABLE API
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 2: Enabling Security Command Center API...${RESET_FORMAT}"

gcloud services enable securitycenter.googleapis.com --quiet
echo "${RED_TEXT}API Enabled successfully.${RESET_FORMAT}"
echo

# ====================================================
# STEP 3: PUBSUB RESOURCES
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Setting up Pub/Sub for Findings Export...${RESET_FORMAT}"

export BUCKET_NAME="scc-export-bucket-$PROJECT_ID"

echo "${BLUE_TEXT}Creating Topic...${RESET_FORMAT}"
gcloud pubsub topics create projects/$PROJECT_ID/topics/export-findings-pubsub-topic

echo "${BLUE_TEXT}Creating Subscription...${RESET_FORMAT}"
gcloud pubsub subscriptions create export-findings-pubsub-topic-sub \
  --topic=projects/$PROJECT_ID/topics/export-findings-pubsub-topic

echo
echo "${RED_TEXT}${BOLD_TEXT}ACTION REQUIRED: Create the Export Configuration manually:${RESET_FORMAT}"
echo "${BLUE_TEXT}Link: https://console.cloud.google.com/security/command-center/config/continuous-exports/pubsub?project=${PROJECT_ID}${RESET_FORMAT}"
echo

# ====================================================
# STEP 4: CONFIRMATION PROMPT
# ====================================================
while true; do
    read -p "${RED_TEXT}${BOLD_TEXT}Do you want to proceed? (Y/n): ${RESET_FORMAT}" confirm
    case "$confirm" in
        [Yy]|"") 
            echo "${BLUE_TEXT}Continuing with setup...${RESET_FORMAT}"
            break
            ;;
        [Nn]) 
            echo "${RED_TEXT}Operation canceled.${RESET_FORMAT}"
            exit 0
            ;;
        *) 
            echo "${RED_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}" 
            ;;
    esac
done
echo

# ====================================================
# STEP 5: COMPUTE INSTANCE
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 5: Creating Compute Instance...${RESET_FORMAT}"

gcloud compute instances create instance-1 --zone=$ZONE \
  --machine-type=e2-micro \
  --scopes=https://www.googleapis.com/auth/cloud-platform

echo "${RED_TEXT}Instance created.${RESET_FORMAT}"
echo

# ====================================================
# STEP 6: BIGQUERY SETUP
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 6: Setting up BigQuery Dataset...${RESET_FORMAT}"

bq --location=$REGION mk --dataset $PROJECT_ID:continuous_export_dataset

echo "${BLUE_TEXT}Configuring BigQuery Export...${RESET_FORMAT}"
gcloud scc bqexports create scc-bq-cont-export \
  --dataset=projects/$PROJECT_ID/datasets/continuous_export_dataset \
  --project=$PROJECT_ID \
  --quiet

echo "${RED_TEXT}BigQuery resources configured.${RESET_FORMAT}"
echo

# ====================================================
# STEP 7: SERVICE ACCOUNTS (GENERATING FINDINGS)
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 7: Creating Service Accounts to Generate Findings...${RESET_FORMAT}"

for i in {0..2}; do
    echo "${BLUE_TEXT}Creating Service Account sccp-test-sa-$i...${RESET_FORMAT}"
    gcloud iam service-accounts create sccp-test-sa-$i
    
    echo "${BLUE_TEXT}Creating Key for sccp-test-sa-$i...${RESET_FORMAT}"
    gcloud iam service-accounts keys create /tmp/sa-key-$i.json \
    --iam-account=sccp-test-sa-$i@$PROJECT_ID.iam.gserviceaccount.com
done
echo

# ====================================================
# STEP 8: MONITORING FINDINGS
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 8: Waiting for Security Findings in BigQuery...${RESET_FORMAT}"

query_findings() {
  bq query --apilog=/dev/null --use_legacy_sql=false --format=pretty \
    "SELECT finding_id, event_time, finding.category FROM continuous_export_dataset.findings"
}

has_findings() {
  echo "$1" | grep -qE '^[|] [a-f0-9]{32} '
}

while true; do
    result=$(query_findings)
    
    if has_findings "$result"; then
        echo "${RED_TEXT}${BOLD_TEXT}Findings detected!${RESET_FORMAT}"
        echo "$result"
        break
    else
        echo "${BLUE_TEXT}No findings yet. Waiting for 100 seconds...${RESET_FORMAT}"
        sleep 100
    fi
done
echo

# ====================================================
# STEP 9: STORAGE SETUP
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 9: Setting up Cloud Storage...${RESET_FORMAT}"

gsutil mb -l $REGION gs://$BUCKET_NAME/
gsutil pap set enforced gs://$BUCKET_NAME

echo "${BLUE_TEXT}Waiting 20 seconds for propagation...${RESET_FORMAT}"
sleep 20
echo

# ====================================================
# STEP 10: EXPORT TO STORAGE
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 10: Exporting Findings to Cloud Storage...${RESET_FORMAT}"

echo "${BLUE_TEXT}Listing findings and saving to JSONL...${RESET_FORMAT}"
gcloud scc findings list "projects/$PROJECT_ID" \
  --format=json | jq -c '.[]' > findings.jsonl

echo "${BLUE_TEXT}Uploading to Bucket...${RESET_FORMAT}"
gsutil cp findings.jsonl gs://$BUCKET_NAME/



# ====================================================
# COMPLETION FOOTER
# ====================================================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}                LAB COMPLETED SUCCESSFULLY!                   ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
