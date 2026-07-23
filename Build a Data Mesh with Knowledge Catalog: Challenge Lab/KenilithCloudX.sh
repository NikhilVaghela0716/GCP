#!/bin/bash

# =========================
# Colors & Text Formatting
# =========================
BLACK_TEXT=$'\033[0;30m'
RED_TEXT=$'\033[0;31m'
GREEN_TEXT=$'\033[0;32m'
YELLOW_TEXT=$'\033[0;33m'
BLUE_TEXT=$'\033[0;34m'
MAGENTA_TEXT=$'\033[0;35m'
CYAN_TEXT=$'\033[0;36m'
WHITE_TEXT=$'\033[0;37m'
ORANGE_TEXT=$'\033[38;5;208m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# =========================
# Header
# =========================
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | KenilithCloudX               ${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# =========================
# Enable Required APIs
# =========================
echo -e "${CYAN_TEXT}${BOLD_TEXT}Enabling required Google Cloud APIs...${RESET_FORMAT}"

gcloud services enable \
  dataplex.googleapis.com \
  datacatalog.googleapis.com \
  dataproc.googleapis.com

echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ APIs Enabled Successfully${RESET_FORMAT}"
echo

# =========================
# Variables
# =========================
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

echo -e "${CYAN_TEXT}${BOLD_TEXT}Project ID :${RESET_FORMAT} ${WHITE_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo -e "${CYAN_TEXT}${BOLD_TEXT}Region     :${RESET_FORMAT} ${WHITE_TEXT}$REGION${RESET_FORMAT}"
echo

# =========================
# Create Lake
# =========================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating Dataplex Lake...${RESET_FORMAT}"

gcloud dataplex lakes create sales-lake \
  --location=$REGION \
  --display-name="Sales Lake"

echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ Sales Lake Created${RESET_FORMAT}"
echo

# =========================
# Create RAW Zone
# =========================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating RAW Customer Zone...${RESET_FORMAT}"

gcloud dataplex zones create raw-customer-zone \
  --lake=sales-lake \
  --location=$REGION \
  --display-name="Raw Customer Zone" \
  --type=RAW \
  --resource-location-type=SINGLE_REGION \
  --discovery-enabled \
  --discovery-schedule="0 * * * *"

echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ RAW Zone Created${RESET_FORMAT}"
echo

# =========================
# Create CURATED Zone
# =========================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating Curated Customer Zone...${RESET_FORMAT}"

gcloud dataplex zones create curated-customer-zone \
  --lake=sales-lake \
  --location=$REGION \
  --display-name="Curated Customer Zone" \
  --type=CURATED \
  --resource-location-type=SINGLE_REGION \
  --discovery-enabled \
  --discovery-schedule="0 * * * *"

echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ Curated Zone Created${RESET_FORMAT}"
echo

# =========================
# Create Customer Engagement Asset
# =========================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating Customer Engagement Asset...${RESET_FORMAT}"

gcloud dataplex assets create customer-engagements \
  --lake=sales-lake \
  --zone=raw-customer-zone \
  --location=$REGION \
  --display-name="Customer Engagements" \
  --resource-type=STORAGE_BUCKET \
  --resource-name=projects/$PROJECT_ID/buckets/$PROJECT_ID-customer-online-sessions \
  --discovery-enabled

echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ Customer Engagement Asset Created${RESET_FORMAT}"
echo

# =========================
# Create Customer Orders Asset
# =========================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating Customer Orders Asset...${RESET_FORMAT}"

gcloud dataplex assets create customer-orders \
  --lake=sales-lake \
  --zone=curated-customer-zone \
  --location=$REGION \
  --display-name="Customer Orders" \
  --resource-type=BIGQUERY_DATASET \
  --resource-name=projects/$PROJECT_ID/datasets/customer_orders \
  --discovery-enabled

echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ Customer Orders Asset Created${RESET_FORMAT}"
echo

# =========================
# Task 2
# =========================
echo -e "${ORANGE_TEXT}${BOLD_TEXT}===============================================================${RESET_FORMAT}"
echo -e "${ORANGE_TEXT}${BOLD_TEXT}⚠ Complete Task 2 (Aspects) Manually in the Console.${RESET_FORMAT}"
echo -e "${ORANGE_TEXT}${BOLD_TEXT}===============================================================${RESET_FORMAT}"
echo

read -p "Press Enter after completing Task 2..."

echo

# =========================
# User Email
# =========================
read -p "Enter User 2 Email: " USER_2

echo
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM Policy...${RESET_FORMAT}"

gcloud dataplex assets add-iam-policy-binding customer-engagements \
  --lake=sales-lake \
  --zone=raw-customer-zone \
  --location=$REGION \
  --member=user:$USER_2 \
  --role=roles/dataplex.dataWriter

echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ IAM Policy Added${RESET_FORMAT}"
echo

# =========================
# Create Data Quality Config
# =========================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating Data Quality Configuration...${RESET_FORMAT}"

cat > dq-customer-orders.yaml <<EOF
rules:
- nonNullExpectation: {}
  column: user_id
  dimension: COMPLETENESS
  threshold: 1

- nonNullExpectation: {}
  column: order_id
  dimension: COMPLETENESS
  threshold: 1

postScanActions:
  bigqueryExport:
    resultsTable: projects/$PROJECT_ID/datasets/orders_dq_dataset/tables/results
EOF

gsutil cp dq-customer-orders.yaml gs://$PROJECT_ID-dq-config/

echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ Configuration Uploaded${RESET_FORMAT}"
echo

# =========================
# Create Data Quality Scan
# =========================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Creating Data Quality Scan...${RESET_FORMAT}"

gcloud dataplex datascans create data-quality customer-orders-data-quality-job \
  --project=$PROJECT_ID \
  --location=$REGION \
  --data-source-resource="//bigquery.googleapis.com/projects/$PROJECT_ID/datasets/customer_orders/tables/ordered_items" \
  --data-quality-spec-file="gs://$PROJECT_ID-dq-config/dq-customer-orders.yaml"

echo
echo -e "${GREEN_TEXT}${BOLD_TEXT}✓ Data Quality Scan Created Successfully${RESET_FORMAT}"
echo

# =========================
# Footer
# =========================
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}                     ✅ LAB FINISHED!                             ${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo -e "${CYAN_TEXT}${BOLD_TEXT}🎉 Congratulations! Your Google Cloud Lab has been completed.${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}🙏 Thank you for learning with KenilithCloudX!${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}${BOLD_TEXT}📢 Subscribe for more hands-on Google Cloud Labs:${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
