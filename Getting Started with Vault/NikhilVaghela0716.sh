#!/bin/bash
set -e

# ================= COLOR DEFINITIONS =================
RED_TEXT=$'\033[1;31m'
GREEN_TEXT=$'\033[1;32m'
YELLOW_TEXT=$'\033[1;33m'
BLUE_TEXT=$'\033[1;34m'
MAGENTA_TEXT=$'\033[1;35m'
CYAN_TEXT=$'\033[1;36m'
WHITE_TEXT=$'\033[1;37m'
GOLD_TEXT=$'\033[38;5;220m'
PURPLE_TEXT=$'\033[38;5;141m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# ===========================================
# WELCOME MESSAGE
# ===========================================
echo -e "${GOLD_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT} 🚀 Welcome to HashiCorp Vault Lab on Google Cloud 🚀 ${RESET_FORMAT}"
echo -e "${CYAN_TEXT}${BOLD_TEXT}            By Nikhil Vaghela${RESET_FORMAT}"
echo -e "${WHITE_TEXT}Learn HashiCorp Vault step-by-step on Google Cloud${RESET_FORMAT}"
echo
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}👉 Subscribe for more GCP & DevOps Labs:${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo

# =========================
# 1. INSTALL VAULT
# =========================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}📦 Installing Vault...${RESET_FORMAT}"
sudo apt update && sudo apt install -y curl gnupg lsb-release jq

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install vault -y

echo -e "${GREEN_TEXT}${BOLD_TEXT}✔ Vault installed:${RESET_FORMAT}"
vault --version
echo

# =========================
# 2. START VAULT DEV SERVER
# =========================
echo -e "${CYAN_TEXT}${BOLD_TEXT}🚀 Starting Vault dev server...${RESET_FORMAT}"
pkill vault || true
vault server -dev -dev-root-token-id="root-token" > vault.log 2>&1 &
sleep 3

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN="root-token"

echo -e "${GREEN_TEXT}${BOLD_TEXT}✔ Vault server started${RESET_FORMAT}"
echo -e "${WHITE_TEXT}VAULT_ADDR=${VAULT_ADDR}${RESET_FORMAT}"
echo -e "${WHITE_TEXT}VAULT_TOKEN=${VAULT_TOKEN}${RESET_FORMAT}"
vault status
echo

# =========================
# 3. KV SECRETS
# =========================
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}🔐 Working with KV secrets${RESET_FORMAT}"
vault kv get secret/hello || true
vault kv put secret/hello foo=world
vault kv put secret/hello foo=world excited=yes
vault kv get secret/hello
vault kv get -field=excited secret/hello > secret.txt

PROJECT_ID=$(gcloud config get-value project)
gsutil cp secret.txt gs://$PROJECT_ID

vault kv delete secret/hello

vault kv put secret/example test=version01
vault kv put secret/example test=version02
vault kv put secret/example test=version03
vault kv get -version=2 secret/example
vault kv delete -versions=2 secret/example
vault kv undelete -versions=2 secret/example
vault kv destroy -versions=2 secret/example || true
echo

# =========================
# 4. ENABLE ANOTHER SECRETS ENGINE
# =========================
echo -e "${CYAN_TEXT}${BOLD_TEXT}🔑 Enabling additional secrets engine${RESET_FORMAT}"
vault secrets enable -path=kv kv || true
vault secrets list

vault kv put kv/hello target=world
vault kv get kv/hello

vault kv put kv/my-secret value="s3c(eT"
vault kv get kv/my-secret
vault kv get -format=json kv/my-secret | jq -r .data.value > my-secret.txt
gsutil cp my-secret.txt gs://$PROJECT_ID
vault kv delete kv/my-secret
vault kv list kv/

vault secrets disable kv/ || true
echo

# =========================
# 5. TOKEN AUTH
# =========================
echo -e "${YELLOW_TEXT}${BOLD_TEXT}🎫 Working with Vault tokens${RESET_FORMAT}"
TOKEN1=$(vault token create -format=json | jq -r .auth.client_token)
vault login $TOKEN1
TOKEN2=$(vault token create -format=json | jq -r .auth.client_token)
vault token revoke $TOKEN1 || true
echo

# =========================
# 6. USERPASS AUTH
# =========================
echo -e "${BLUE_TEXT}${BOLD_TEXT}👤 Enabling userpass authentication${RESET_FORMAT}"
vault auth enable userpass || true
vault write auth/userpass/users/admin password=password! policies=admin
vault login -method=userpass username=admin password=password!
echo

# =========================
# 7. TRANSIT SECRETS ENGINE
# =========================
echo -e "${PURPLE_TEXT}${BOLD_TEXT}🔐 Using Transit secrets engine${RESET_FORMAT}"
vault secrets enable transit || true
vault write -f transit/keys/my-key

PLAINTEXT="Learn Vault!"
ENC=$(echo -n "$PLAINTEXT" | base64 | vault write -format=json transit/encrypt/my-key plaintext=- | jq -r .data.ciphertext)

DECRYPTED_BASE64=$(vault write -format=json transit/decrypt/my-key ciphertext="$ENC" | jq -r .data.plaintext)
echo "$DECRYPTED_BASE64" | base64 --decode > decrypted-string.txt

cat decrypted-string.txt
gsutil cp decrypted-string.txt gs://$PROJECT_ID

# =========================
# FINAL MESSAGE
# =========================
echo
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}      🎉 LAB COMPLETED SUCCESSFULLY 🎉                  ${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo -e "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo -e "${PURPLE_TEXT}${BOLD_TEXT}Subscribe for more Google Cloud Labs 🚀${RESET_FORMAT}"

