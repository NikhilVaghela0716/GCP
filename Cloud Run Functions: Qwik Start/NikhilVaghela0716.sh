#!/bin/bash

# ====================================================
# COLOR DEFINITIONS
# ====================================================
BLUE_TEXT=$(tput setaf 4)
RED_TEXT=$(tput setaf 1)
BOLD_TEXT=$(tput bold)
RESET_FORMAT=$(tput sgr0)

clear

# ====================================================
# PRE-FLIGHT CHECKS
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | NIKHIL VAGHELA 🚀            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ====================================================
# SETUP & CONFIGURATION
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Enabling Required GCP Services...${RESET_FORMAT}"

gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  osconfig.googleapis.com \
  pubsub.googleapis.com \
  cloudaicompanion.googleapis.com

echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Project Environment...${RESET_FORMAT}"

export PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/region $REGION

# ====================================================
# IAM CONFIGURATION
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Configuring IAM Permissions...${RESET_FORMAT}"

SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role roles/eventarc.eventReceiver

# Update IAM Policy for Audit Logs
gcloud projects get-iam-policy $PROJECT_ID > policy.yaml

cat <<EOF >> policy.yaml
auditConfigs:
- auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_READ
  - logType: DATA_WRITE
  service: compute.googleapis.com
EOF

gcloud projects set-iam-policy $PROJECT_ID policy.yaml

# ====================================================
# DEPLOYMENT FUNCTION
# ====================================================
deploy_with_retry() {
  local function_name=$1
  shift
  local attempts=0
  local max_attempts=5
  
  while [ $attempts -lt $max_attempts ]; do
    echo "${BLUE_TEXT}Attempt $((attempts+1)): Deploying $function_name...${RESET_FORMAT}"
    
    if gcloud functions deploy $function_name "$@"; then
      echo "${RED_TEXT}$function_name deployed successfully!${RESET_FORMAT}"
      return 0
    else
      attempts=$((attempts+1))
      echo "${RED_TEXT}Deployment failed. Retrying in 30 seconds...${RESET_FORMAT}"
      sleep 30
    fi
  done
  
  echo "${RED_TEXT}Failed to deploy $function_name after $max_attempts attempts${RESET_FORMAT}"
  return 1
}



# ====================================================
# 1. HTTP FUNCTION (NODE.JS)
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Deploying HTTP Trigger Function...${RESET_FORMAT}"
echo

mkdir ~/hello-http && cd $_

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');

functions.http('helloWorld', (req, res) => {
  res.status(200).send('HTTP with Node.js in GCF 2nd gen!');
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-http-function",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

deploy_with_retry nodejs-http-function \
  --gen2 \
  --runtime nodejs22 \
  --entry-point helloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --timeout 600s \
  --max-instances 1 \
  --allow-unauthenticated

echo "${BLUE_TEXT}${BOLD_TEXT}Testing HTTP Function...${RESET_FORMAT}"
gcloud functions call nodejs-http-function --gen2 --region $REGION

# ====================================================
# 2. STORAGE TRIGGER FUNCTION
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Deploying Storage Trigger Function...${RESET_FORMAT}"
echo

mkdir ~/hello-storage && cd $_

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('helloStorage', (cloudevent) => {
  console.log('Cloud Storage event with Node.js in GCF 2nd gen!');
  console.log(cloudevent);
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-storage-function",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

BUCKET="gs://gcf-gen2-storage-$PROJECT_ID"
gsutil mb -l $REGION $BUCKET

deploy_with_retry nodejs-storage-function \
  --gen2 \
  --runtime nodejs22 \
  --entry-point helloStorage \
  --source . \
  --region $REGION \
  --trigger-bucket $BUCKET \
  --trigger-location $REGION \
  --max-instances 1



echo "${BLUE_TEXT}Triggering Storage Event...${RESET_FORMAT}"
echo "Hello World" > random.txt
gsutil cp random.txt $BUCKET/random.txt

echo "${BLUE_TEXT}${BOLD_TEXT}Checking Storage Function Logs...${RESET_FORMAT}"
gcloud functions logs read nodejs-storage-function \
  --region $REGION --gen2 --limit=100 --format "value(log)"

# ====================================================
# 3. VM LABELER FUNCTION (AUDIT LOGS)
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Deploying VM Labeler Function (Eventarc)...${RESET_FORMAT}"
echo

cd ~
git clone https://github.com/GoogleCloudPlatform/eventarc-samples.git
cd ~/eventarc-samples/gce-vm-labeler/gcf/nodejs

deploy_with_retry gce-vm-labeler \
  --gen2 \
  --runtime nodejs22 \
  --entry-point labelVmCreation \
  --source . \
  --region $REGION \
  --trigger-event-filters="type=google.cloud.audit.log.v1.written,serviceName=compute.googleapis.com,methodName=beta.compute.instances.insert" \
  --trigger-location $REGION \
  --max-instances 1



# Create Test VM
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Test VM Instance to trigger labeler...${RESET_FORMAT}"
gcloud compute instances create instance-1 --project=$PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-osconfig=TRUE,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250311,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud --reservation-affinity=any && printf 'agentsRule:\n  packageState: installed\n  version: latest\ninstanceFilter:\n  inclusionLabels:\n  - labels:\n      goog-ops-agent-policy: v2-x86-template-1-4-0\n' > config.yaml && gcloud compute instances ops-agents policies create goog-ops-agent-v2-x86-template-1-4-0-$ZONE --project=$PROJECT_ID --zone=$ZONE --file=config.yaml && gcloud compute resource-policies create snapshot-schedule default-schedule-1 --project=$PROJECT_ID --region=$REGION --max-retention-days=14 --on-source-disk-delete=keep-auto-snapshots --daily-schedule --start-time=08:00 && gcloud compute disks add-resource-policies instance-1 --project=$PROJECT_ID --zone=$ZONE --resource-policies=projects/$PROJECT_ID/regions/$REGION/resourcePolicies/default-schedule-1

echo "${BLUE_TEXT}${BOLD_TEXT}Verifying VM Labels...${RESET_FORMAT}"
gcloud compute instances describe instance-1 --zone $ZONE

# ====================================================
# 4. PYTHON FUNCTION (ENV VARS)
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Deploying Colored Hello World Function...${RESET_FORMAT}"
echo

mkdir ~/hello-world-colored && cd $_
touch requirements.txt

cat > main.py <<EOF
import os

color = os.environ.get('COLOR')

def hello_world(request):
    return f'<body style="background-color:{color}"><h1>Hello World!</h1></body>'
EOF

deploy_with_retry hello-world-colored \
  --gen2 \
  --runtime python311 \
  --entry-point hello_world \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --update-env-vars COLOR=orange \
  --max-instances 1

# ====================================================
# 5. GO FUNCTION (CONCURRENCY & MIN INSTANCES)
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Deploying Slow Go Function...${RESET_FORMAT}"
echo

mkdir ~/min-instances && cd $_
touch main.go

cat > main.go <<EOF
package p

import (
        "fmt"
        "net/http"
        "time"
)

func init() {
        time.Sleep(10 * time.Second)
}

func HelloWorld(w http.ResponseWriter, r *http.Request) {
        fmt.Fprint(w, "Slow HTTP Go in GCF 2nd gen!")
}
EOF

echo "module example.com/mod" > go.mod

deploy_with_retry slow-function \
  --gen2 \
  --runtime go123 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --max-instances 4

echo "${BLUE_TEXT}${BOLD_TEXT}Testing Slow Function...${RESET_FORMAT}"
gcloud functions call slow-function --gen2 --region $REGION

# ====================================================
# 6. CLOUD RUN INTEGRATION
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Deploying as Cloud Run Service...${RESET_FORMAT}"

export spcl_project=$(echo "$PROJECT_ID" | sed 's/-/--/g; s/$/__/g')
export my_region=$(echo "$REGION" | sed 's/-/--/g; s/$/__/g')
export full_path="$REGION-docker.pkg.dev/$PROJECT_ID/gcf-artifacts/$spcl_project$my_region"
export full_path="${full_path}slow--function:version_1"

gcloud run deploy slow-function \
--image=$full_path \
--min-instances=1 \
--max-instances=4 \
--region=$REGION \
--project=$PROJECT_ID

gcloud functions call slow-function --gen2 --region $REGION
SLOW_URL=$(gcloud functions describe slow-function --region $REGION --gen2 --format="value(serviceConfig.uri)")

echo
echo "${RED_TEXT}${BOLD_TEXT}Load Testing Slow Function URL: $SLOW_URL${RESET_FORMAT}"
hey -n 10 -c 10 $SLOW_URL

# ====================================================
# PROGRESS CHECK
# ====================================================
function check_progress {
    while true; do
        echo
        echo "${RED_TEXT}${BOLD_TEXT}PLEASE VERIFY YOUR PROGRESS UP TO TASK 6${RESET_FORMAT}"
        echo
        read -p "${BLUE_TEXT}${BOLD_TEXT}Have you completed Task 6? (Y/N): ${RESET_FORMAT}" user_input
        
        case $user_input in
            [Yy]*)
                echo
                echo "${RED_TEXT}${BOLD_TEXT}Proceeding to next steps...${RESET_FORMAT}"
                echo
                break
                ;;
            [Nn]*)
                echo
                echo "${RED_TEXT}${BOLD_TEXT}Please complete Task 6 first${RESET_FORMAT}"
                ;;
            *)
                echo
                echo "${RED_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}"
                ;;
        esac
    done
}

check_progress

# ====================================================
# CLEANUP & FINAL DEPLOYMENT
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Cleaning Up Previous Deployment...${RESET_FORMAT}"
gcloud run services delete slow-function --region $REGION --quiet

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Deploying Concurrent Function...${RESET_FORMAT}"

deploy_with_retry slow-concurrent-function \
  --gen2 \
  --runtime go123 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 4



# Deploy as Cloud Run with Concurrency
export full_path="${REGION}-docker.pkg.dev/${PROJECT_ID}/gcf-artifacts/${spcl_project}${my_region}slow--concurrent--function:version_1"

gcloud run deploy slow-concurrent-function \
--image=$full_path \
--concurrency=100 \
--cpu=1 \
--max-instances=4 \
--set-env-vars=LOG_EXECUTION_ID=true \
--region=$REGION \
--project=$PROJECT_ID \
&& gcloud run services update-traffic slow-concurrent-function --to-latest --region=$REGION

SLOW_CONCURRENT_URL=$(gcloud functions describe slow-concurrent-function --region $REGION --gen2 --format="value(serviceConfig.uri)")
hey -n 10 -c 10 $SLOW_CONCURRENT_URL

# ====================================================
# COMPLETION FOOTER
# ====================================================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}                 ✅ LAB COMPLETED SUCCESSFULLY!               ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
