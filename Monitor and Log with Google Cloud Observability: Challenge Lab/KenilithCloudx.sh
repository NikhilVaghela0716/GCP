#!/bin/bash

# Define color variables
RED=$'\033[0;91m'
BLUE=$'\033[0;94m'
RESET=$'\033[0m'
BOLD=$'\033[1m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}            🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀               ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"

gcloud services enable monitoring.googleapis.com

export ZONE=$(gcloud compute instances list video-queue-monitor --format 'csv[no-heading](zone)')
export REGION="${ZONE%-*}"
export INSTANCE_ID=$(gcloud compute instances describe video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE" --format="get(id)")

gcloud compute instances stop video-queue-monitor --zone $ZONE

cat > startup-script.sh <<EOF_START
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

sudo apt update && sudo apt -y
sudo apt-get install wget -y
sudo apt-get -y install git
sudo chmod 777 /usr/local/
sudo wget https://go.dev/dl/go1.22.8.linux-amd64.tar.gz 
sudo tar -C /usr/local -xzf go1.22.8.linux-amd64.tar.gz
export PATH=\$PATH:/usr/local/go/bin

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo service google-cloud-ops-agent start

mkdir /work
mkdir /work/go
mkdir /work/go/cache
export GOPATH=/work/go
export GOCACHE=/work/go/cache

cd /work/go
mkdir video
gsutil cp gs://spls/gsp338/video_queue/main.go /work/go/video/main.go

go get go.opencensus.io
go get contrib.go.opencensus.io/exporter/stackdriver

export MY_PROJECT_ID=\$DEVSHELL_PROJECT_ID
export MY_GCE_INSTANCE_ID=$INSTANCE_ID
export MY_GCE_INSTANCE_ZONE=\$ZONE

cd /work
go mod init go/video/main
go mod tidy
go run /work/go/video/main.go
EOF_START

gcloud compute instances add-metadata video-queue-monitor \
  --zone $ZONE \
  --metadata-from-file startup-script=startup-script.sh

gcloud compute instances start video-queue-monitor --zone $ZONE

gcloud logging metrics create $METRIC \
    --description="Metric for high resolution video uploads" \
    --log-filter='textPayload=("file_format=4K" OR "file_format=8K")'

cat > email-channel.json <<EOF_END
{
  "type": "email",
  "displayName": "cloudwalabanda",
  "description": "Awesome",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_END

gcloud beta monitoring channels create --channel-content-from-file="email-channel.json"

email_channel_info=$(gcloud beta monitoring channels list)
email_channel_id=$(echo "$email_channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

cat > cloudwalabanda.json <<EOF_END
{
  "displayName": "cloudwalabanda",
  "conditions": [
    {
      "displayName": "VM Instance - logging/user/large_video_upload_rate",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/$METRIC\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
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
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$email_channel_id"
  ]
}
EOF_END

gcloud alpha monitoring policies create --policy-from-file=cloudwalabanda.json

echo "${BLUE}${BOLD}Click here:${RESET} ${BLUE}${BOLD}https://console.cloud.google.com/monitoring/dashboards?project=$DEVSHELL_PROJECT_ID${RESET}"

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
