#!/bin/bash

# =========================
# COLOR DEFINITIONS
# =========================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[1;31m'
GREEN_TEXT=$'\033[1;32m'
YELLOW_TEXT=$'\033[1;33m'
BLUE_TEXT=$'\033[1;34m'
MAGENTA_TEXT=$'\033[1;35m'
CYAN_TEXT=$'\033[1;36m'
WHITE_TEXT=$'\033[1;37m'
GOLD_TEXT=$'\033[38;5;220m'

RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# =========================
# WELCOME BANNER
# =========================
echo "${GOLD_TEXT}${BOLD_TEXT}══════════════════════════════════════════════════${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        🚀 WELCOME TO NIKHIL VAGHELA 🚀        ${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}     Google Cloud • DevOps • Hands-on Labs     ${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}══════════════════════════════════════════════════${RESET_FORMAT}"
echo

# =========================
# AUTH & PROJECT SETUP
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}🔐 Checking GCP Authentication...${RESET_FORMAT}"
gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/region $REGION

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID

# =========================
# SPANNER SQL INSERT
# =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Inserting record using SQL...${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-db --instance=banking-instance \
 --sql="INSERT INTO Customer (CustomerId, Name, Location) VALUES ('bdaaaa97-1b4b-4e58-b4ad-84030de92235', 'Richard Nelson', 'Ada Ohio')"

# =========================
# PYTHON TRANSACTION INSERT
# =========================
cat > insert.py <<EOF_CP
from google.cloud import spanner

INSTANCE_ID = "banking-instance"
DATABASE_ID = "banking-db"

spanner_client = spanner.Client()
instance = spanner_client.instance(INSTANCE_ID)
database = instance.database(DATABASE_ID)

def insert_customer(transaction):
    row_ct = transaction.execute_update(
        "INSERT INTO Customer (CustomerId, Name, Location)"
        "VALUES ('b2b4002d-7813-4551-b83b-366ef95f9273', 'Shana Underwood', 'Ely Iowa')"
    )
    print(f"{row_ct} record(s) inserted.")

database.run_in_transaction(insert_customer)
EOF_CP

echo "${YELLOW_TEXT}${BOLD_TEXT}🐍 Running Python insert...${RESET_FORMAT}"
python3 insert.py

sleep 60

# =========================
# BATCH INSERT
# =========================
cat > batch_insert.py <<EOF_CP
from google.cloud import spanner

INSTANCE_ID = "banking-instance"
DATABASE_ID = "banking-db"

spanner_client = spanner.Client()
instance = spanner_client.instance(INSTANCE_ID)
database = instance.database(DATABASE_ID)

with database.batch() as batch:
    batch.insert(
        table="Customer",
        columns=("CustomerId", "Name", "Location"),
        values=[
            ('edfc683f-bd87-4bab-9423-01d1b2307c0d', 'John Elkins', 'Roy Utah'),
            ('1f3842ca-4529-40ff-acdd-88e8a87eb404', 'Martin Madrid', 'Ames Iowa'),
            ('3320d98e-6437-4515-9e83-137f105f7fbc', 'Theresa Henderson', 'Anna Texas'),
            ('6b2b2774-add9-4881-8702-d179af0518d8', 'Norma Carter', 'Bend Oregon'),
        ],
    )

print("Rows inserted successfully")
EOF_CP

echo "${YELLOW_TEXT}${BOLD_TEXT}📊 Running batch insert...${RESET_FORMAT}"
python3 batch_insert.py

sleep 60

# =========================
# GCS SETUP
# =========================
echo "${CYAN_TEXT}${BOLD_TEXT}☁ Creating Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb gs://$DEVSHELL_PROJECT_ID
touch emptyfile
gsutil cp emptyfile gs://$DEVSHELL_PROJECT_ID/tmp/emptyfile

# =========================
# DATAFLOW JOB
# =========================
echo "${YELLOW_TEXT}${BOLD_TEXT}⚙ Restarting Dataflow API...${RESET_FORMAT}"
gcloud services disable dataflow.googleapis.com --force
gcloud services enable dataflow.googleapis.com

sleep 90

echo "${GREEN_TEXT}${BOLD_TEXT}🚚 Starting Dataflow job...${RESET_FORMAT}"
gcloud dataflow jobs run spanner-load \
 --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_Cloud_Spanner \
 --region $REGION \
 --staging-location gs://$DEVSHELL_PROJECT_ID/tmp/ \
 --parameters instanceId=banking-instance,databaseId=banking-db,importManifest=gs://cloud-training/OCBL372/manifest.json

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔍 Track Dataflow Job:${RESET_FORMAT}"
echo "${UNDERLINE_TEXT}${CYAN_TEXT}https://console.cloud.google.com/dataflow/jobs?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${GOLD_TEXT}${BOLD_TEXT}══════════════════════════════════════════════════${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}        ✅ LAB COMPLETED SUCCESSFULLY!        ${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}══════════════════════════════════════════════════${RESET_FORMAT}"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}📢 Subscribe for more GCP Hands-on Labs${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}👉 https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
