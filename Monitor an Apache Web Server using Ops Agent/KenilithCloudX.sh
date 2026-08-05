#!/bin/bash

set -e
set -o pipefail

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

gcloud auth list

export PROJECT_ID="$DEVSHELL_PROJECT_ID"

export ZONE=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone "$ZONE"

echo "Project : $PROJECT_ID"
echo "Zone    : $ZONE"
echo "Region  : $REGION"
echo

# =========================
# Create VM
# =========================
gcloud compute instances create quickstart-vm \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --tags=http-server,https-server

# =========================
# Firewall Rules
# =========================
if ! gcloud compute firewall-rules describe default-allow-http >/dev/null 2>&1; then
    gcloud compute firewall-rules create default-allow-http \
        --target-tags=http-server \
        --allow=tcp:80 \
        --description="Allow HTTP traffic"
fi

if ! gcloud compute firewall-rules describe default-allow-https >/dev/null 2>&1; then
    gcloud compute firewall-rules create default-allow-https \
        --target-tags=https-server \
        --allow=tcp:443 \
        --description="Allow HTTPS traffic"
fi

# =========================
# Create VM Setup Script
# =========================
cat > cp_disk.sh <<'EOF'
#!/bin/bash

set -e

sudo apt-get update
sudo apt-get install -y apache2 php

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

sudo cp /etc/google-cloud-ops-agent/config.yaml \
/etc/google-cloud-ops-agent/config.yaml.bak

sudo tee /etc/google-cloud-ops-agent/config.yaml >/dev/null <<CONFIG
metrics:
  receivers:
    apache:
      type: apache
  service:
    pipelines:
      apache:
        receivers:
          - apache

logging:
  receivers:
    apache_access:
      type: apache_access
    apache_error:
      type: apache_error
  service:
    pipelines:
      apache:
        receivers:
          - apache_access
          - apache_error
CONFIG

sudo systemctl restart google-cloud-ops-agent

sleep 60
EOF

chmod +x cp_disk.sh

# =========================
# Copy & Execute Script
# =========================
gcloud compute scp cp_disk.sh \
    quickstart-vm:/tmp \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --quiet

gcloud compute ssh quickstart-vm \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --quiet \
    --command="bash /tmp/cp_disk.sh"

# =========================
# Notification Channel
# =========================
cat > cp-channel.json <<EOF
{
  "type": "pubsub",
  "displayName": "kenilith",
  "description": "subscribe to kenilith",
  "labels": {
    "topic": "projects/$PROJECT_ID/topics/notificationTopic"
  }
}
EOF

gcloud beta monitoring channels create \
    --channel-content-from-file=cp-channel.json

channel_id=$(gcloud beta monitoring channels list \
    --format="value(name)" | head -n 1)

# =========================
# Alert Policy
# =========================
cat > stopped-vm-alert-policy.json <<EOF
{
  "displayName": "Apache traffic above threshold",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - workload/apache.traffic",
      "conditionThreshold": {
        "filter": "resource.type = \\"gce_instance\\" AND metric.type = \\"workload.googleapis.com/apache.traffic\\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 4000
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "1800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$channel_id"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF

gcloud alpha monitoring policies create \
    --policy-from-file=stopped-vm-alert-policy.json

# =========================
# Footer
# =========================
echo
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
