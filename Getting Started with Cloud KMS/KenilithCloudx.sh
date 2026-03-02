#!/bin/bash

# --- Color and Formatting Definitions ---
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}            🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀               ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"

# --- Task 1: Set Variables & Create Bucket ---
# Note: Ensure this BUCKET_NAME matches the one provided in your lab instructions
export BUCKET_NAME="qwiklabs-gcp-04-6e22d1b242eb-kms_lab"
export KEYRING_NAME="labkey"
export CRYPTOKEY_NAME="qwiklab"
export USER_EMAIL=$(gcloud auth list --limit=1 2>/dev/null | grep '@' | awk '{print $2}')

echo "${BLUE}Creating bucket: ${BUCKET_NAME}...${RESET}"
gsutil mb gs://${BUCKET_NAME}

# --- Task 2: Review Data ---
echo "${BLUE}Downloading sample data...${RESET}"
gsutil cp gs://${GOOGLE_CLOUD_PROJECT}-kms-lab-data/finance-dept/inbox/1.txt .

# --- Task 3: Enable Cloud KMS ---
echo "${BLUE}Enabling KMS API...${RESET}"
gcloud services enable cloudkms.googleapis.com

# --- Task 4: Create Keyring and Cryptokey ---
echo "${BLUE}Creating KeyRing and CryptoKey...${RESET}"
gcloud kms keyrings create $KEYRING_NAME --location global
gcloud kms keys create $CRYPTOKEY_NAME --location global \
      --keyring $KEYRING_NAME \
      --purpose encryption

# --- Task 5: Encrypt Data (Individual File) ---
echo "${BLUE}Encrypting individual file (Task 5)...${RESET}"
PLAINTEXT=$(cat 1.txt | base64 -w0)

curl -s "https://cloudkms.googleapis.com/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
  -d "{\"plaintext\":\"$PLAINTEXT\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .ciphertext -r > 1.encrypted

gsutil cp 1.encrypted gs://${BUCKET_NAME}

# --- Task 6: Configure IAM Permissions ---
echo "${BLUE}Configuring IAM permissions...${RESET}"
gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
    --location global \
    --member user:$USER_EMAIL \
    --role roles/cloudkms.admin

gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
    --location global \
    --member user:$USER_EMAIL \
    --role roles/cloudkms.cryptoKeyEncrypterDecrypter

# --- Task 7: Bulk Backup & Encryption ---
echo "${BLUE}Running bulk encryption script (Task 7)...${RESET}"
gsutil -m cp -r gs://${GOOGLE_CLOUD_PROJECT}-kms-lab-data/finance-dept .

MYDIR=finance-dept
FILES=$(find $MYDIR -type f -not -name "*.encrypted")
for file in $FILES; do
  PLAINTEXT=$(cat $file | base64 -w0)
  curl -s "https://cloudkms.googleapis.com/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
    -d "{\"plaintext\":\"$PLAINTEXT\"}" \
    -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type:application/json" \
  | jq .ciphertext -r > $file.encrypted
done

gsutil -m cp finance-dept/inbox/*.encrypted gs://${BUCKET_NAME}/finance-dept/inbox

# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED}${BOLD}==============================================================${RESET}"
echo "${RED}${BOLD}                LAB COMPLETED SUCCESSFULLY!                ${RESET}"
echo "${RED}${BOLD}==============================================================${RESET}"
echo
echo "${BLUE}${BOLD}🙏 Thanks for learning with Kenilith Cloudx${RESET}"
echo "${RED}${BOLD}📢 Subscribe for more Google Cloud Labs:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@KenilithCloudx${RESET}"
echo
