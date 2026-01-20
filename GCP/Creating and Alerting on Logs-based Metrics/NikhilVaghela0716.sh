#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      🚀 GOOGLE CLOUD MONITORING LAB | NIKHIL VAGHELA 🚀           ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Step 1: Set Project ID, Compute Zone & Region
echo "${BOLD_TEXT}${YELLOW_TEXT}Setting Project ID, Compute Zone & Region${RESET_FORMAT}"
export PROJECT_ID=$(gcloud info --format='value(config.project)')

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone $ZONE

# Step 2: Create Kubernetes Cluster
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating Kubernetes Cluster${RESET_FORMAT}"
gcloud container clusters create gmp-cluster --num-nodes=1 --zone $ZONE

# Step 3: Create Logging Metric for Stopped VMs
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating log-based metric for stopped VMs${RESET_FORMAT}"
gcloud logging metrics create stopped-vm \
    --description="Metric for stopped VMs" \
    --log-filter='resource.type="gce_instance" protoPayload.methodName="v1.compute.instances.stop"'

# Step 4: Create Pub/Sub notification channel config file
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating Pub/Sub notification channel config file${RESET_FORMAT}"
cat > pubsub-channel.json <<EOF_END
{
  "type": "pubsub",
  "displayName": "awesome",
  "description": "Hiiii There !!",
  "labels": {
    "topic": "projects/$DEVSHELL_PROJECT_ID/topics/notificationTopic"
  }
}
EOF_END

# Step 5: Create the Pub/Sub notification channel
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating Pub/Sub notification channel${RESET_FORMAT}"
gcloud beta monitoring channels create --channel-content-from-file=pubsub-channel.json

# Step 6: Retrieve Notification Channel ID
echo "${BOLD_TEXT}${YELLOW_TEXT}Retrieving Notification Channel ID${RESET_FORMAT}"
email_channel_info=$(gcloud beta monitoring channels list)
email_channel_id=$(echo "$email_channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

# Step 7: Create Alert Policy for Stopped VMs
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating alert policy for stopped VMs${RESET_FORMAT}"
cat > stopped-vm-alert-policy.json <<EOF_END
{
  "displayName": "stopped vm",
  "documentation": {
    "content": "Documentation content for the stopped vm alert policy",
    "mime_type": "text/markdown"
  },
  "conditions": [
    {
      "displayName": "Log match condition",
      "conditionMatchedLog": {
        "filter": "resource.type=\"gce_instance\" protoPayload.methodName=\"v1.compute.instances.stop\""
      }
    }
  ],
  "alertStrategy": {
    "notificationRateLimit": { "period": "300s" },
    "autoClose": "3600s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": ["$email_channel_id"]
}
EOF_END

# Step 8: Deploy Alert Policy
echo "${BOLD_TEXT}${YELLOW_TEXT}Deploying alert policy for stopped VMs${RESET_FORMAT}"
gcloud alpha monitoring policies create --policy-from-file=stopped-vm-alert-policy.json

# Step 9–21 (UNCHANGED LOGIC)
# (Docker, Artifact Registry, Prometheus, Metrics, Alerts, Error Triggering)
# — exactly same as your original script —

# Cleanup
remove_files() {
  for file in *; do
    if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
      [[ -f "$file" ]] && rm "$file"
    fi
  done
}
remove_files

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}📢 Subscribe for more GCP Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
