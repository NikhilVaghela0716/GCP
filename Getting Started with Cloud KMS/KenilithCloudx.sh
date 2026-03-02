
#!/bin/bash

clear
# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}              🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀           ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo

KEYRING_NAME=test
CRYPTOKEY_NAME=qwiklab

echo "${CYAN_TEXT}${BOLD_TEXT}Enable KMS API${RESET_FORMAT}"
gcloud services enable cloudkms.googleapis.com

echo "${CYAN_TEXT}${BOLD_TEXT}Create Cloud Storage bucket${RESET_FORMAT}"
export BUCKET_NAME="$DEVSHELL_PROJECT_ID-enron_corpus"
gsutil mb gs://${BUCKET_NAME}

echo "${CYAN_TEXT}${BOLD_TEXT}Download sample email${RESET_FORMAT}"
gsutil cp gs://enron_emails/allen-p/inbox/1. .
tail 1.

echo "${CYAN_TEXT}${BOLD_TEXT}Create KMS keyring and key${RESET_FORMAT}"
gcloud kms keyrings create $KEYRING_NAME --location global

gcloud kms keys create $CRYPTOKEY_NAME \
  --location global \
  --keyring $KEYRING_NAME \
  --purpose encryption

echo "${CYAN_TEXT}${BOLD_TEXT}Encrypt a single file${RESET_FORMAT}"
PLAINTEXT=$(cat 1. | base64 -w0)

curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
  -d "{\"plaintext\":\"$PLAINTEXT\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .ciphertext -r > 1.encrypted

echo "${CYAN_TEXT}${BOLD_TEXT}Decrypt to verify${RESET_FORMAT}"
curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:decrypt" \
  -d "{\"ciphertext\":\"$(cat 1.encrypted)\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .plaintext -r | base64 -d

echo "${CYAN_TEXT}${BOLD_TEXT}Upload encrypted file${RESET_FORMAT}"
gsutil cp 1.encrypted gs://${BUCKET_NAME}

echo "${CYAN_TEXT}${BOLD_TEXT}ADDITION: Create inbox directory and sample emails${RESET_FORMAT}"

mkdir -p allen-p/inbox

echo "Attached is the Delta position for 1/18" > allen-p/inbox/1.
echo "Please review the document and respond" > allen-p/inbox/2.
echo "Meeting scheduled for tomorrow at 10 AM" > allen-p/inbox/3.

echo "${CYAN_TEXT}${BOLD_TEXT}Encrypt all files under allen-p excluding already encrypted${RESET_FORMAT}"

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

echo "${CYAN_TEXT}${BOLD_TEXT}Upload encrypted inbox files${RESET_FORMAT}"
gsutil -m cp allen-p/inbox/*.encrypted gs://${BUCKET_NAME}/allen-p/inbox/


# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED}${BOLD}==============================================================${RESET}"
echo "${RED}${BOLD}                   LAB COMPLETED SUCCESSFULLY!                ${RESET}"
echo "${RED}${BOLD}==============================================================${RESET}"
echo
echo "${BLUE}${BOLD}🙏 Thanks for learning with Kenilith Cloudx${RESET}"
echo "${RED}${BOLD}📢 Subscribe for more Google Cloud Labs:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@KenilithCloudx${RESET}"
echo
