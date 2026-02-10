#!/bin/bash

# =========================
# COLOR DEFINITIONS (RED & BLUE ONLY)
# =========================
RED_TEXT='\033[0;31m'
BLUE_TEXT='\033[0;34m'
BOLD_TEXT='\033[1m'
UNDERLINE_TEXT='\033[4m'
RESET_FORMAT='\033[0m'

# Aliases (to keep existing echo -e usage working)
RED=$RED_TEXT
BLUE=$BLUE_TEXT
BOLD=$BOLD_TEXT
RESET=$RESET_FORMAT

# =========================
# WELCOME MESSAGE
# =========================
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀            ${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Set region and zone
echo -e "${RED}Setting up region and zone...${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

echo -e "${BLUE}Region: $REGION${RESET}"
echo -e "${BLUE}Zone: $ZONE${RESET}"
echo ""

# Get project details
echo -e "${RED}Getting project information...${RESET}"
PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

echo -e "${BLUE}Project ID: $PROJECT_ID${RESET}"
echo -e "${BLUE}Project Number: $PROJECT_NUMBER${RESET}"
echo ""

# Clone repository and setup Terraform
echo -e "${RED}Cloning repository and setting up Terraform...${RESET}"
git clone https://github.com/Redislabs-Solution-Architects/gcp-microservices-demo-qwiklabs.git
pushd gcp-microservices-demo-qwiklabs

cat <<EOF > terraform.tfvars
gcp_project_id = "$(gcloud config list project --format='value(core.project)')"
gcp_region = "$REGION"
EOF

terraform init

echo -e "${RED}Applying Terraform configuration...${RESET}"
terraform apply -auto-approve

# Export Redis endpoints
export REDIS_DEST=$(terraform output db_private_endpoint | tr -d '"')
export REDIS_DEST_PASS=$(terraform output db_password | tr -d '"')
export REDIS_ENDPOINT="${REDIS_DEST},user=default,password=${REDIS_DEST_PASS}"

echo -e "${BLUE}Redis Destination: $REDIS_DEST${RESET}"

# Configure kubectl
echo -e "${RED}Configuring kubectl...${RESET}"
gcloud container clusters get-credentials \
$(terraform output -raw gke_cluster_name) \
--region $(terraform output -raw region)

# Get external frontend service
echo -e "${RED}Frontend external service:${RESET}"
kubectl get service frontend-external -n redis

echo -e "${RED}${BOLD}TASK 2: Migrating to Redis Cloud${RESET}"

# Set namespace
kubectl config set-context --current --namespace=redis

echo -e "${RED}Current cartservice environment:${RESET}"
kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq

# Create redis credentials secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: redis-creds
type: Opaque
stringData:
  REDIS_SOURCE: redis://redis-cart:6379
  REDIS_DEST: redis://${REDIS_DEST}
  REDIS_DEST_PASS: ${REDIS_DEST_PASS}
EOF

echo -e "${BLUE}Secret created successfully${RESET}"

# Apply redis migrator job
kubectl apply -f https://raw.githubusercontent.com/Redislabs-Solution-Architects/gcp-microservices-demo-qwiklabs/main/util/redis-migrator-job.yaml
echo -e "${BLUE}Redis migrator job applied${RESET}"

echo -e "${RED}Current cartservice environment after migrator:${RESET}"
kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq

# Patch deployment to use Redis Cloud
kubectl patch deployment cartservice --patch '{"spec":{"template":{"spec":{"containers":[{"name":"server","env":[{"name":"REDIS_ADDR","value":"'$REDIS_ENDPOINT'"}]}]}}}}'

echo -e "${BLUE}Cartservice patched to use Redis Cloud${RESET}"

echo -e "${RED}Updated cartservice environment:${RESET}"
kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq

echo ""
echo -e "${RED}${BOLD}TASK 3: Testing rollback to local Redis${RESET}"

# Rollback to local Redis
kubectl patch deployment cartservice --patch '{"spec":{"template":{"spec":{"containers":[{"name":"server","env":[{"name":"REDIS_ADDR","value":"redis-cart:6379"}]}]}}}}'

echo -e "${BLUE}Rolled back to local Redis${RESET}"

echo -e "${RED}Current cartservice environment after rollback:${RESET}"
kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq

echo ""
echo -e "${RED}${BOLD}TASK 4: Final migration to Redis Cloud${RESET}"

# Final migration to Redis Cloud
kubectl patch deployment cartservice --patch '{"spec":{"template":{"spec":{"containers":[{"name":"server","env":[{"name":"REDIS_ADDR","value":"'$REDIS_ENDPOINT'"}]}]}}}}'

echo -e "${BLUE}Final migration to Redis Cloud completed${RESET}"

echo -e "${RED}Current cartservice environment:${RESET}"
kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq

# Delete local Redis deployment
kubectl delete deploy redis-cart
echo -e "${BLUE}Local Redis deployment deleted${RESET}"

# =========================
# COMPLETION FOOTER
# =========================
echo
echo -e "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo -e "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo

popd
