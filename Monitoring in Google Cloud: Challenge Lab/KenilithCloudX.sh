#!/bin/bash

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


ZONE=$(gcloud compute instances list \
  --project=$DEVSHELL_PROJECT_ID \
  --format='value(ZONE)' | head -n 1)

INSTANCE_ID=$(gcloud compute instances describe apache-vm \
  --zone=$ZONE \
  --format='value(id)')

VM_EXTERNAL_IP=$(gcloud compute instances describe apache-vm \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "${CYAN_TEXT}${REVERSE_TEXT} Zone: $ZONE ${RESET_FORMAT}"
echo "${CYAN_TEXT}${REVERSE_TEXT} Instance ID: $INSTANCE_ID ${RESET_FORMAT}"
echo "${CYAN_TEXT}${REVERSE_TEXT} External IP: $VM_EXTERNAL_IP ${RESET_FORMAT}"
echo

cat > cp_disk.sh <<'EOF'
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
sudo bash add-logging-agent-repo.sh --also-install

curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
sudo bash add-monitoring-agent-repo.sh --also-install

(cd /etc/stackdriver/collectd.d/ && sudo curl -O \
https://raw.githubusercontent.com/Stackdriver/stackdriver-agent-service-configs/master/etc/collectd.d/apache.conf)

sudo service stackdriver-agent restart
EOF

gcloud compute scp cp_disk.sh apache-vm:/tmp --zone=$ZONE --quiet
gcloud compute ssh apache-vm --zone=$ZONE --quiet --command="bash /tmp/cp_disk.sh"

echo "${GREEN_TEXT}${BOLD_TEXT}Monitoring agent installed${RESET_FORMAT}"
echo


gcloud monitoring uptime create drabhishek \
  --resource-type=uptime-url \
  --resource-labels=host=$VM_EXTERNAL_IP,path=/,port=80

echo "${GREEN_TEXT}${BOLD_TEXT}Uptime check created${RESET_FORMAT}"
echo


cat > email-channel.json <<EOF
{
  "type": "email",
  "displayName": "drabhishek",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF

gcloud beta monitoring channels create \
  --channel-content-from-file=email-channel.json

CHANNEL_ID=$(gcloud beta monitoring channels list \
  --format="value(name)" | head -n 1)

echo "${GREEN_TEXT}${BOLD_TEXT}Notification channel created${RESET_FORMAT}"
echo

# ================= ALERT POLICY =================
# Section 5: Alert Policy
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating alert policy...${RESET_FORMAT}"
channel_info=$(gcloud beta monitoring channels list)
channel_id=$(echo "$channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

cat > app-engine-error-percent-policy.json <<EOF_CP
{
  "displayName": "alert",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - Traffic",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/apache/traffic\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "300s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 3072
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
EOF_CP

gcloud alpha monitoring policies create --policy-from-file="app-engine-error-percent-policy.json"
echo "${GREEN_TEXT}${BOLD_TEXT}Alert policy created successfully!${RESET_FORMAT}"
echo
# ================= LOG-BASED METRIC =================

PROJECT_ID=$(gcloud config get-value project)

gcloud logging metrics create drabhi \
  --description="Count Apache 200 OK responses" \
  --log-filter='resource.type="gce_instance"
logName="projects/'"$PROJECT_ID"'/logs/apache-access"
textPayload:"200"'

echo "${GREEN_TEXT}${BOLD_TEXT}Log-based metric 'drabhi' created${RESET_FORMAT}"
echo
# Section 6: Quick Links
echo "${WHITE_TEXT}${BOLD_TEXT}Dashboard: ${YELLOW_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/monitoring/dashboards?&project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Metrics: ${YELLOW_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/logs/metrics/edit?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo


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
