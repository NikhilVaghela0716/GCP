#!/bin/bash

# 1. Set Environment Variables
# Using the Project ID to ensure the bucket name is unique
export BUCKET_NAME="qwiklabs-gcp-${GOOGLE_CLOUD_PROJECT}-kms-lab"
export KEYRING_NAME="labkey"
export CRYPTOKEY_NAME="qwiklab"
export USER_EMAIL=$(gcloud auth list --limit=1 2>/dev/null | grep '@' | awk '{print $2}')

echo "Starting lab tasks for Project: $GOOGLE_CLOUD_PROJECT..."

# 2. Create Cloud Storage Bucket
gsutil mb gs://${BUCKET_NAME}

# 3. Enable Cloud KMS API
gcloud services enable cloudkms.googleapis.com

# 4. Create KeyRing and CryptoKey
gcloud kms keyrings create $KEYRING_NAME --location global

gcloud kms keys create $CRYPTOKEY_NAME --location global \
      --keyring $KEYRING_NAME \
      --purpose encryption

# 5. Configure IAM Permissions
# Granting Admin and Encrypter/Decrypter roles to the current user
gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
    --location global \
    --member user:$USER_EMAIL \
    --role roles/cloudkms.admin

gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
    --location global \
    --member user:$USER_EMAIL \
    --role roles/cloudkms.cryptoKeyEncrypterDecrypter

# 6. Prepare Data & Bulk Encrypt
# Copy data from the source bucket
gsutil -m cp -r gs://${GOOGLE_CLOUD_PROJECT}-kms-lab-data/finance-dept .

# Loop through files, Base64 encode, Encrypt via KMS API, and save as .encrypted
MYDIR=finance-dept
FILES=$(find $MYDIR -type f -not -name "*.encrypted")

for file in $FILES; do
  echo "Encrypting $file..."
  PLAINTEXT=$(cat $file | base64 -w0)
  
  curl -s "https://cloudkms.googleapis.com/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
    -d "{\"plaintext\":\"$PLAINTEXT\"}" \
    -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type:application/json" \
  | jq .ciphertext -r > $file.encrypted
done

# 7. Upload Encrypted Files to your Bucket
gsutil -m cp finance-dept/inbox/*.encrypted gs://${BUCKET_NAME}/finance-dept/inbox/

echo "Lab Completed Successfully!"
