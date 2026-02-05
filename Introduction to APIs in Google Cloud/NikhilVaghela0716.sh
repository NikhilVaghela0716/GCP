#!/bin/bash

# ====================================================
# COLOR DEFINITIONS
# ====================================================
BLUE_TEXT=$(tput setaf 4)
RED_TEXT=$(tput setaf 1)
BOLD_TEXT=$(tput bold)
RESET_FORMAT=$(tput sgr0)

# ====================================================
# PRE-FLIGHT CHECKS
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Checking system requirements...${RESET_FORMAT}"
for cmd in gcloud gsutil curl nano; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "${RED_TEXT}Error: $cmd could not be found.${RESET_FORMAT}"
        exit 1
    fi
done
echo "${BLUE_TEXT}System requirements met.${RESET_FORMAT}"
echo

# ====================================================
# STEP 1: REGION SETUP
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 1: Configuring Compute Region${RESET_FORMAT}"

read -p "${RED_TEXT}${BOLD_TEXT}Enter REGION [us-central1]: ${RESET_FORMAT}" USER_REGION
REGION=${USER_REGION:-us-central1}

gcloud config set compute/region $REGION
echo "${BLUE_TEXT}Region set to: $REGION${RESET_FORMAT}"
echo

# ====================================================
# STEP 2: CONFIGURATION FILE
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 2: Creating API configuration file (values.json)${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)

cat > values.json << EOL
{
  "name": "${PROJECT_ID}-bucket",
  "location": "us",
  "storageClass": "multi_regional"
}
EOL

echo "${BLUE_TEXT}Configuration created for Project ID: $PROJECT_ID${RESET_FORMAT}"
export PROJECT_ID
echo

# ====================================================
# STEP 3: ENABLE API
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Enabling Cloud Storage API${RESET_FORMAT}"

gcloud services enable storage-api.googleapis.com
echo "${BLUE_TEXT}Storage API enabled.${RESET_FORMAT}"
echo

# ====================================================
# STEP 4: OAUTH AUTHENTICATION
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 4: OAuth Token Configuration${RESET_FORMAT}"
echo "${BLUE_TEXT}Please follow these steps to generate a token:${RESET_FORMAT}"
echo "${BLUE_TEXT}1. Visit: https://developers.google.com/oauthplayground/${RESET_FORMAT}"
echo "${BLUE_TEXT}2. Select 'Cloud Storage API V1'${RESET_FORMAT}"
echo "${BLUE_TEXT}3. Select Scope: https://www.googleapis.com/auth/devstorage.full_control${RESET_FORMAT}"
echo "${BLUE_TEXT}4. Authorize and Exchange authorization code for tokens${RESET_FORMAT}"
echo "${BLUE_TEXT}5. Copy the 'Access token'${RESET_FORMAT}"
echo

read -p "${RED_TEXT}${BOLD_TEXT}Paste your OAuth2 Access Token here: ${RESET_FORMAT}" OAUTH2_TOKEN

if [ -z "$OAUTH2_TOKEN" ]; then
    echo "${RED_TEXT}Error: OAuth2 token is required.${RESET_FORMAT}"
    exit 1
fi
export OAUTH2_TOKEN
echo

# ====================================================
# STEP 5: BUCKET CREATION (API)
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 5: Creating Bucket via REST API${RESET_FORMAT}"

# Initial API Call
RESPONSE=$(curl -s -X POST --data-binary @values.json \
    -H "Authorization: Bearer $OAUTH2_TOKEN" \
    -H "Content-Type: application/json" \
    "https://www.googleapis.com/storage/v1/b?project=$PROJECT_ID")

# Check for errors (specifically name conflicts)
if echo "$RESPONSE" | grep -q "error"; then
    if echo "$RESPONSE" | grep -q "bucket name is restricted"; then
        echo "${RED_TEXT}Bucket name conflict detected. Generating unique name...${RESET_FORMAT}"
        
        # Logic to rename bucket
        RANDOM_SUFFIX=$(date +%s | cut -c 6-10)
        BUCKET_NAME="${PROJECT_ID}-bucket-${RANDOM_SUFFIX}"
        
        # Update JSON
        sed -i "s/\"name\": \".*\"/\"name\": \"$BUCKET_NAME\"/" values.json
        
        echo "${BLUE_TEXT}Retrying with name: $BUCKET_NAME${RESET_FORMAT}"
        
        # Retry API Call
        RESPONSE=$(curl -s -X POST --data-binary @values.json \
            -H "Authorization: Bearer $OAUTH2_TOKEN" \
            -H "Content-Type: application/json" \
            "https://www.googleapis.com/storage/v1/b?project=$PROJECT_ID")
            
        if echo "$RESPONSE" | grep -q "error"; then
             echo "${RED_TEXT}Retry failed. Please check token or permissions.${RESET_FORMAT}"
             echo "$RESPONSE"
             exit 1
        fi
    else
        echo "${RED_TEXT}API Request failed.${RESET_FORMAT}"
        echo "$RESPONSE"
        exit 1
    fi
fi

# Extract bucket name
BUCKET_NAME=$(echo "$RESPONSE" | grep -o '"name": *"[^"]*"' | cut -d'"' -f4)
export BUCKET_NAME

echo "${BLUE_TEXT}Bucket created successfully: $BUCKET_NAME${RESET_FORMAT}"
echo

# ====================================================
# STEP 6: FILE UPLOAD (API)
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 6: Uploading Object via REST API${RESET_FORMAT}"

echo "${BLUE_TEXT}Generating sample image...${RESET_FORMAT}"
BASE64_IMG="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVQI12P4//8/AAX+Av7czFnnAAAAAElFTkSuQmCC"
echo "$BASE64_IMG" | base64 -d > demo-image.png

OBJECT=$(realpath demo-image.png)

echo "${BLUE_TEXT}Uploading demo-image.png...${RESET_FORMAT}"
RESPONSE=$(curl -s -X POST --data-binary @$OBJECT \
    -H "Authorization: Bearer $OAUTH2_TOKEN" \
    -H "Content-Type: image/png" \
    "https://www.googleapis.com/upload/storage/v1/b/$BUCKET_NAME/o?uploadType=media&name=demo-image")

if echo "$RESPONSE" | grep -q "error"; then
    echo "${RED_TEXT}Upload failed.${RESET_FORMAT}"
    echo "$RESPONSE"
    exit 1
fi

echo "${BLUE_TEXT}File uploaded to: gs://$BUCKET_NAME/demo-image${RESET_FORMAT}"

# Verification
if gsutil ls "gs://$BUCKET_NAME/demo-image" &>/dev/null; then
    echo "${BLUE_TEXT}Verification: File exists.${RESET_FORMAT}"
else
    echo "${RED_TEXT}Warning: Verification failed.${RESET_FORMAT}"
fi

# ====================================================
# COMPLETION FOOTER
# ====================================================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}         ✅ LAB COMPLETED SUCCESSFULLY!                       ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
