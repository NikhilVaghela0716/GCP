#!/bin/bash

# Define color variables
RED=$'\033[0;91m'
BLUE=$'\033[0;94m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}            🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀             ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo ""

echo "${RED}${BOLD}  --> Initializing Video Queue Monitoring Configuration...${RESET}"
echo ""

# User Input Section
echo "${RED}${BOLD}[ USER INPUT ]${RESET}"
read -p "${BLUE}Enter custom_metric: ${RESET}" custom_metric
read -p "${BLUE}Enter VALUE: ${RESET}" VALUE
echo ""

# Authentication Check
echo "${RED}${BOLD}[ AUTHENTICATION ]${RESET}"
echo "${BLUE}  --> Checking active GCP account...${RESET}"
gcloud auth list
echo ""

# Project Configuration
echo "${RED}${BOLD}[ PROJECT SETUP ]${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID
echo "${BLUE}  --> Project ID : $PROJECT_ID${RESET}"
echo ""

# Service Enablement
echo "${RED}${BOLD}[ SERVICE ENABLEMENT ]${RESET}"
echo "${BLUE}  --> Enabling Monitoring API...${RESET}"
gcloud services enable monitoring.googleapis.com --project="$DEVSHELL_PROJECT_ID"
echo "${BLUE}  --> Monitoring API enabled successfully!${RESET}"
echo ""

# Zone and Region Configuration
echo "${RED}${BOLD}[ REGION SETUP ]${RESET}"
ZONE=$(gcloud compute instances list --project="$DEVSHELL_PROJECT_ID" --format="get(zone)" --limit=1)
gcloud config set compute/zone $ZONE
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION
echo "${BLUE}  --> Zone   : $ZONE${RESET}"
echo "${BLUE}  --> Region : $REGION${RESET}"
echo ""

# Instance Configuration
echo "${RED}${BOLD}[ INSTANCE SETUP ]${RESET}"
echo "${BLUE}  --> Retrieving instance details...${RESET}"
INSTANCE_ID=$(gcloud compute instances describe video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE" --format="get(id)")
echo "${BLUE}  --> Stopping video-queue-monitor instance...${RESET}"
gcloud compute instances stop video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE"
echo "${BLUE}  --> Instance stopped successfully!${RESET}"
echo ""

# Startup Script Creation
echo "${RED}${BOLD}[ STARTUP SCRIPT ]${RESET}"
echo "${BLUE}  --> Creating startup script...${RESET}"
cat > startup-script.sh <<EOF_CP
#!/bin/bash

ZONE="$ZONE"
REGION="${ZONE%-*}"
PROJECT_ID="$DEVSHELL_PROJECT_ID"

echo "ZONE: $ZONE"
echo "REGION: $REGION"
echo "PROJECT_ID: $PROJECT_ID"

sudo apt update && sudo apt -y
sudo apt-get install wget -y
sudo apt-get -y install git
sudo chmod 777 /usr/local/
sudo wget https://go.dev/dl/go1.22.8.linux-amd64.tar.gz 
sudo tar -C /usr/local -xzf go1.22.8.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo service google-cloud-ops-agent start

mkdir -p /work/go/cache
export GOPATH=/work/go
export GOCACHE=/work/go/cache

cd /work/go
mkdir -p video
gsutil cp gs://spls/gsp338/video_queue/main.go /work/go/video/main.go

go get go.opencensus.io
go get contrib.go.opencensus.io/exporter/stackdriver

# Set project metadata
export MY_PROJECT_ID="$DEVSHELL_PROJECT_ID"
export MY_GCE_INSTANCE_ID="$INSTANCE_ID"
export MY_GCE_INSTANCE_ZONE="$ZONE"

cd /work
go mod init go/video/main
go mod tidy
go run /work/go/video/main.go
EOF_CP

echo "${BLUE}  --> Startup script created successfully!${RESET}"
echo ""

# Apply Startup Script and Start Instance
echo "${RED}${BOLD}[ INSTANCE DEPLOYMENT ]${RESET}"
echo "${BLUE}  --> Applying startup script and starting instance...${RESET}"
gcloud compute instances add-metadata video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE" --metadata-from-file startup-script=startup-script.sh
gcloud compute instances start video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE"
echo "${BLUE}  --> Instance configured and started successfully!${RESET}"
echo ""

# Logging Metric Creation
echo "${RED}${BOLD}[ LOGGING METRIC ]${RESET}"
echo "${BLUE}  --> Creating logging metric for high resolution videos...${RESET}"
gcloud logging metrics create $custom_metric \
    --description="Metric for high resolution video uploads" \
    --log-filter='textPayload=("file_format=4K" OR "file_format=8K")'
echo "${BLUE}  --> Logging metric created successfully!${RESET}"
echo ""

# Notification Channel Creation
echo "${RED}${BOLD}[ NOTIFICATION CHANNEL ]${RESET}"
echo "${BLUE}  --> Creating email notification channel...${RESET}"
cat > email-channel.json <<EOF_CP
{
  "type": "email",
  "displayName": "DrAbhishekAlerts",
  "description": "Video Queue Monitoring by Dr. Abhishek",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_CP

gcloud beta monitoring channels create --channel-content-from-file="email-channel.json"
echo "${BLUE}  --> Notification channel created successfully!${RESET}"
echo ""

# Alert Policy Creation
echo "${RED}${BOLD}[ ALERT POLICY ]${RESET}"
echo "${BLUE}  --> Creating alert policy...${RESET}"
channel_info=$(gcloud beta monitoring channels list)
channel_id=$(echo "$channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

cat > video-queue-alert.json <<EOF_CP
{
  "displayName": "DrAbhishekVideoAlerts",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "High Resolution Video Upload Rate",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/$custom_metric\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": $VALUE
      }
    }
  ],
  "alertStrategy": {
    "notificationPrompts": [
      "OPENED"
    ]
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$channel_id"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_CP

gcloud alpha monitoring policies create --policy-from-file=video-queue-alert.json
echo "${BLUE}  --> Alert policy created successfully!${RESET}"
echo ""

# =========================
# COMPLETION FOOTER
# =========================
echo "${RED}${BOLD}==================================================================${RESET}"
echo "${RED}${BOLD}                  LAB COMPLETED SUCCESSFULLY !                   ${RESET}"
echo "${RED}${BOLD}==================================================================${RESET}"
echo ""
echo "${BLUE}${BOLD}  Thanks for learning with Kenilith Cloudx${RESET}"
echo "${RED}${BOLD}  Subscribe for more Google Cloud Labs :${RESET}"
echo "${BLUE}${BOLD}  https://www.youtube.com/@KenilithCloudx${RESET}"
echo ""
