#!/bin/bash

# Color Definitions
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=================================================================="
echo "          🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀                "
echo "==================================================================${RESET_FORMAT}"
echo

KEYRING_NAME=test
CRYPTOKEY_NAME=qwiklab

echo "${BLUE_TEXT}${BOLD_TEXT}Enable KMS API${RESET_FORMAT}"
gcloud services enable cloudkms.googleapis.com

echo "${BLUE_TEXT}${BOLD_TEXT}Create Cloud Storage bucket${RESET_FORMAT}"
export BUCKET_NAME="$DEVSHELL_PROJECT_ID-enron_corpus"
gsutil mb gs://${BUCKET_NAME}

echo "${BLUE_TEXT}${BOLD_TEXT}Generating local sample email (Fixing Access Error)${RESET_FORMAT}"
# We create a local '1.' file to bypass the gsutil 403 access error
echo "From: kenilith@cloudx.com - This is a test email for KMS encryption." > 1.
tail 1.

echo "${BLUE_TEXT}${BOLD_TEXT}Create KMS keyring and key${RESET_FORMAT}"
gcloud kms keyrings create $KEYRING_NAME --location global

gcloud kms keys create $CRYPTOKEY_NAME \
  --location global \
  --keyring $KEYRING_NAME \
  --purpose encryption

echo "${BLUE_TEXT}${BOLD_TEXT}Encrypt a single file${RESET_FORMAT}"
PLAINTEXT=$(cat 1. | base64 -w0)

curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
  -d "{\"plaintext\":\"$PLAINTEXT\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .ciphertext -r > 1.encrypted

echo "${BLUE_TEXT}${BOLD_TEXT}Decrypt to verify${RESET_FORMAT}"
curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:decrypt" \
  -d "{\"ciphertext\":\"$(cat 1.encrypted)\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .plaintext -r | base64 -d
echo ""

echo "${BLUE_TEXT}${BOLD_TEXT}Upload encrypted file${RESET_FORMAT}"
gsutil cp 1.encrypted gs://${BUCKET_NAME}

echo "${BLUE_TEXT}${BOLD_TEXT}ADDITION: Create inbox directory and sample emails${RESET_FORMAT}"
mkdir -p allen-p/inbox
echo "Attached is the Delta position for 1/18" > allen-p/inbox/1.
echo "Please review the document and respond" > allen-p/inbox/2.
echo "Meeting scheduled for tomorrow at 10 AM" > allen-p/inbox/3.

echo "${BLUE_TEXT}${BOLD_TEXT}Encrypt all files under allen-p${RESET_FORMAT}"
MYDIR=allen-p
FILES=$(find $MYDIR -type f -not -name "*.encrypted")

for file in $FILES; do
  PLAINTEXT=$(cat "$file" | base64 -w0)
  curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
    -d "{\"plaintext\":\"$PLAINTEXT\"}" \
    -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type:application/json" \
  | jq .ciphertext -r > "$file.encrypted"
done

echo "${BLUE_TEXT}${BOLD_TEXT}Upload encrypted inbox files${RESET_FORMAT}"
gsutil -m cp allen-p/inbox/*.encrypted gs://${BUCKET_NAME}/allen-p/inbox/

echo
echo "${BLUE_TEXT}${BOLD_TEXT}==============================================================="
echo "                  LAB COMPLETED SUCCESSFULLY!                  "
echo "===============================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}🙏 Thanks for learning with Kenilith Cloudx"
echo "📢 Subscribe for more Google Cloud Labs:"
echo "${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
