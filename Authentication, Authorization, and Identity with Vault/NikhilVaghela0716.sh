#!/bin/bash

# ================= COLOR DEFINITIONS =================
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

# ==========================================
# WELCOME MESSAGE
# ==========================================
echo "${GOLD_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      WELCOME TO NIKHIL VAGHELA CLOUD LABS${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        HASHICORP VAULT – SECRETS MANAGEMENT LAB${RESET_FORMAT}"
echo "${GOLD_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Learn Secure Secrets Management using HashiCorp Vault${RESET_FORMAT}"
echo

# ==========================================
# AUTH CHECK
# ==========================================
echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Checking Google Cloud authentication...${RESET_FORMAT}"
gcloud auth list

export PROJECT_ID=$(gcloud config get-value project)
echo "${BLUE_TEXT}${BOLD_TEXT}Project ID:${RESET_FORMAT} ${WHITE_TEXT}$PROJECT_ID${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Starting HashiCorp Vault Installation${RESET_FORMAT}"

# ==========================================
# INSTALL VAULT
# ==========================================
echo "${YELLOW_TEXT}${BOLD_TEXT}Adding HashiCorp repository and installing Vault...${RESET_FORMAT}"
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update
sudo apt-get install -y vault

echo "${GREEN_TEXT}${BOLD_TEXT}✔ Vault installation completed successfully${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Verifying Vault installation...${RESET_FORMAT}"
vault --version

# ==========================================
# START VAULT SERVER
# ==========================================
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Starting Vault server in development mode...${RESET_FORMAT}"
nohup vault server -dev > vault_server.log 2>&1 &

sleep 5

export VAULT_ADDR='http://127.0.0.1:8200'

echo "${YELLOW_TEXT}${BOLD_TEXT}Checking Vault server status...${RESET_FORMAT}"
vault status

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✔ Vault server is running successfully${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}❌ Vault server failed to start. Check vault_server.log${RESET_FORMAT}"
    exit 1
fi

# ==========================================
# VAULT CONFIGURATION
# ==========================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔐 Configuring Vault Secrets and Authentication${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Storing MySQL credentials in Vault...${RESET_FORMAT}"
vault kv put secret/mysql/webapp db_name="users" username="admin" password="passw0rd"

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling AppRole authentication...${RESET_FORMAT}"
vault auth enable approle

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Jenkins policy...${RESET_FORMAT}"
vault policy write jenkins -<<EOF
path "secret/data/mysql/webapp" {
  capabilities = [ "read" ]
}
EOF

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating AppRole for Jenkins...${RESET_FORMAT}"
vault write auth/approle/role/jenkins token_policies="jenkins" \
    token_ttl=1h token_max_ttl=4h

echo "${YELLOW_TEXT}${BOLD_TEXT}AppRole configuration:${RESET_FORMAT}"
vault read auth/approle/role/jenkins

# ==========================================
# APPROLE LOGIN
# ==========================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔑 Generating AppRole Credentials${RESET_FORMAT}"

ROLE_ID=$(vault read -field=role_id auth/approle/role/jenkins/role-id)
SECRET_ID=$(vault write -force -field=secret_id auth/approle/role/jenkins/secret-id)

echo "${BLUE_TEXT}Role ID:${RESET_FORMAT} $ROLE_ID"
echo "${BLUE_TEXT}Secret ID:${RESET_FORMAT} $SECRET_ID"

echo "${YELLOW_TEXT}${BOLD_TEXT}Logging in using AppRole...${RESET_FORMAT}"
TOKEN=$(vault write -field=token auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID")
export APP_TOKEN="$TOKEN"

echo "${GREEN_TEXT}${BOLD_TEXT}✔ AppRole token generated${RESET_FORMAT}"

# ==========================================
# SECRET ACCESS
# ==========================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}🧪 Testing AppRole access${RESET_FORMAT}"
VAULT_TOKEN=$APP_TOKEN vault kv get secret/mysql/webapp

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Extracting secrets to files...${RESET_FORMAT}"
VAULT_TOKEN=$APP_TOKEN vault kv get -format=json secret/mysql/webapp | jq -r .data.data.db_name > db_name.txt
VAULT_TOKEN=$APP_TOKEN vault kv get -format=json secret/mysql/webapp | jq -r .data.data.username > username.txt
VAULT_TOKEN=$APP_TOKEN vault kv get -format=json secret/mysql/webapp | jq -r .data.data.password > password.txt

echo "${GREEN_TEXT}${BOLD_TEXT}✔ Secret files created${RESET_FORMAT}"

# ==========================================
# UPLOAD TO GCS
# ==========================================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}☁ Uploading secret files to Google Cloud Storage${RESET_FORMAT}"
gsutil cp *.txt gs://$PROJECT_ID

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✔ Files uploaded to gs://$PROJECT_ID${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}❌ Upload failed${RESET_FORMAT}"
fi

# ==========================================
# FINAL MESSAGE
# ==========================================
echo
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}      🎉 LAB COMPLETED SUCCESSFULLY 🎉                  ${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo -e "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo -e "${PURPLE_TEXT}${BOLD_TEXT}Subscribe for more Google Cloud Labs 🚀${RESET_FORMAT}"
echo

