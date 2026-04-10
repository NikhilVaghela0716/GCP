#!/bin/bash
# Define color variables
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀              ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo ""

# Ask user for ZONE (with validation + color)
while true; do
  echo -ne "${RED_TEXT}${BOLD_TEXT}Enter your GCP Zone (e.g. us-central1-a): ${RESET_FORMAT}"
  read ZONE
  if [[ -n "$ZONE" ]]; then
    break
  else
    echo "${RED_TEXT}${BOLD_TEXT}⚠️  ZONE cannot be empty. Please enter a valid zone.${RESET_FORMAT}"
  fi
done

echo "${BLUE_TEXT}${BOLD_TEXT}>>> Setting compute zone to: $ZONE ${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

export PROJECT_ID=$(gcloud info --format='value(config.project)')
echo "${BLUE_TEXT}${BOLD_TEXT}>>> Fetching credentials for cluster 'central'...${RESET_FORMAT}"
gcloud container clusters get-credentials central --zone $ZONE

echo "${BLUE_TEXT}${BOLD_TEXT}>>> Cloning microservices-demo repository...${RESET_FORMAT}"
git clone https://github.com/xiangshen-dk/microservices-demo.git
cd microservices-demo

echo "${BLUE_TEXT}${BOLD_TEXT}>>> Deploying Kubernetes manifests...${RESET_FORMAT}"
kubectl apply -f release/kubernetes-manifests.yaml
sleep 30

echo "${BLUE_TEXT}${BOLD_TEXT}>>> Creating Cloud Logging metric: Error_Rate_SLI...${RESET_FORMAT}"
gcloud logging metrics create Error_Rate_SLI \
  --description="Error rate for recommendationservice" \
  --log-filter="resource.type=\"k8s_container\" severity=ERROR labels.\"k8s-pod/app\": \"recommendationservice\""
sleep 30

echo "${BLUE_TEXT}${BOLD_TEXT}>>> Creating alerting policy from awesome.json...${RESET_FORMAT}"
cat > awesome.json <<EOF_END
{
  "displayName": "Error Rate SLI",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "Kubernetes Container - logging/user/Error_Rate_SLI",
      "conditionThreshold": {
        "filter": "resource.type = \"k8s_container\" AND metric.type = \"logging.googleapis.com/user/Error_Rate_SLI\"",
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
        "thresholdValue": 0.5
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "604800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_END
gcloud alpha monitoring policies create --policy-from-file="awesome.json"

# =========================
# COMPLETION FOOTER
# =========================
echo ""
echo "${RED_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}              ✅ LAB COMPLETED SUCCESSFULLY !                    ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo ""
echo "${BLUE_TEXT}${BOLD_TEXT}  Thanks for learning with Kenilith Cloudx${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  Subscribe for more Google Cloud Labs :${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}  https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo ""
