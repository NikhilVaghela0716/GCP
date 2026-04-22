#!/bin/bash

# Define color variables
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo -e "${BLUE_TEXT}==================================================================${NO_COLOR}"
echo -e "${BLUE_TEXT}            🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀             ${NO_COLOR}"
echo -e "${BLUE_TEXT}==================================================================${NO_COLOR}"
echo ""


# Step 1: Set compute region, project ID & project number
echo "${BOLD_TEXT}${BLUE_TEXT}Setting region, project ID & project number${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Step 2: Enable required services
echo "${BOLD_TEXT}${RED_TEXT}Enabling Cloud Scheduler and Cloud Run APIs${RESET_FORMAT}"
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable cloudfunctions.googleapis.com

# Step 3: Add IAM policy binding for Artifact Registry
echo "${BOLD_TEXT}${BLUE_TEXT}Granting Artifact Registry reader role to Compute Engine default service account${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/artifactregistry.reader"

# Step 4: Copy training files and move into directory
echo "${BOLD_TEXT}${RED_TEXT}Copying training files and changing directory${RESET_FORMAT}"
gcloud storage cp -r gs://spls/gsp649/* . && cd gcf-automated-resource-cleanup/
WORKDIR=$(pwd)

# Step 5: Install apache2-utils
echo "${BOLD_TEXT}${BLUE_TEXT}Installing apache2-utils${RESET_FORMAT}"
sudo apt-get update
sudo apt-get install apache2-utils -y

# Step 6: Move to migrate-storage directory
echo "${BOLD_TEXT}${RED_TEXT}Moving to migrate-storage directory${RESET_FORMAT}"
cd $WORKDIR/migrate-storage

# Step 7: Create public serving bucket
echo "${BOLD_TEXT}${BLUE_TEXT}Creating public serving bucket${RESET_FORMAT}"
gcloud storage buckets create  gs://${PROJECT_ID}-serving-bucket -l $REGION

# Step 8: Make entire bucket publicly readable
echo "${BOLD_TEXT}${RED_TEXT}Making serving bucket publicly readable${RESET_FORMAT}"
gsutil acl ch -u allUsers:R gs://${PROJECT_ID}-serving-bucket

# Step 9: Upload test file to serving bucket
echo "${BOLD_TEXT}${BLUE_TEXT}Uploading testfile.txt to serving bucket${RESET_FORMAT}"
gcloud storage cp $WORKDIR/migrate-storage/testfile.txt  gs://${PROJECT_ID}-serving-bucket

# Step 10: Make test file publicly accessible
echo "${BOLD_TEXT}${RED_TEXT}Making testfile.txt publicly accessible${RESET_FORMAT}"
gsutil acl ch -u allUsers:R gs://${PROJECT_ID}-serving-bucket/testfile.txt

# Step 11: Test file availability via curl
echo "${BOLD_TEXT}${BLUE_TEXT}Testing public access to testfile.txt${RESET_FORMAT}"
curl http://storage.googleapis.com/${PROJECT_ID}-serving-bucket/testfile.txt

# Step 12: Create idle bucket
echo "${BOLD_TEXT}${RED_TEXT}Creating idle bucket${RESET_FORMAT}"
gcloud storage buckets create gs://${PROJECT_ID}-idle-bucket -l $REGION
export IDLE_BUCKET_NAME=$PROJECT_ID-idle-bucket

# Step 13: View function call in main.py
echo "${BOLD_TEXT}${BLUE_TEXT}Viewing migrate_storage call in main.py${RESET_FORMAT}"
cat $WORKDIR/migrate-storage/main.py | grep "migrate_storage(" -A 15

# Step 14: Replace placeholder with actual project ID
echo "${BOLD_TEXT}${RED_TEXT}Replacing <project-id> in main.py${RESET_FORMAT}"
sed -i "s/<project-id>/$PROJECT_ID/" $WORKDIR/migrate-storage/main.py

# Step 15: Disable Cloud Functions temporarily
echo "${BOLD_TEXT}${BLUE_TEXT}Disabling Cloud Functions API temporarily${RESET_FORMAT}"
gcloud services disable cloudfunctions.googleapis.com

# Step 16: Wait 10 seconds
echo "${BOLD_TEXT}${RED_TEXT}Sleeping for 10 seconds...${RESET_FORMAT}"
sleep 10

# Step 17: Re-enable Cloud Functions
echo "${BOLD_TEXT}${BLUE_TEXT}Re-enabling Cloud Functions API${RESET_FORMAT}"
gcloud services enable cloudfunctions.googleapis.com

# Step 18: Deploy the function using Cloud Functions Gen2
echo "${BOLD_TEXT}${RED_TEXT}Deploying Cloud Function (Gen2)${RESET_FORMAT}"
gcloud functions deploy migrate_storage --gen2 --trigger-http --runtime=python39 --region $REGION --allow-unauthenticated

# Step 19: Fetch the function URL
echo "${BOLD_TEXT}${BLUE_TEXT}Fetching deployed function URL${RESET_FORMAT}"
export FUNCTION_URL=$(gcloud functions describe migrate_storage --format=json --region $REGION | jq -r '.url')

# Step 20: Replace IDLE_BUCKET_NAME placeholder in incident.json
echo "${BOLD_TEXT}${RED_TEXT}Replacing IDLE_BUCKET_NAME placeholder in incident.json${RESET_FORMAT}"
export IDLE_BUCKET_NAME=$PROJECT_ID-idle-bucket
sed -i "s/\\\$IDLE_BUCKET_NAME/$IDLE_BUCKET_NAME/" $WORKDIR/migrate-storage/incident.json

# Step 21: Trigger the function using curl
echo "${BOLD_TEXT}${BLUE_TEXT}Triggering function via HTTP request${RESET_FORMAT}"
envsubst < $WORKDIR/migrate-storage/incident.json | curl -X POST -H "Content-Type: application/json" $FUNCTION_URL -d @-

# Step 22: Verify default storage class
echo "${BOLD_TEXT}${RED_TEXT}Verifying default storage class for idle bucket${RESET_FORMAT}"
gsutil defstorageclass get gs://$PROJECT_ID-idle-bucket

echo

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files

# =========================
# COMPLETION FOOTER
# =========================
echo -e "${RED_TEXT}==================================================================${NO_COLOR}"
echo -e "${RED_TEXT}                  LAB COMPLETED SUCCESSFULLY !                   ${NO_COLOR}"
echo -e "${RED_TEXT}==================================================================${NO_COLOR}"
echo ""
echo -e "${BLUE_TEXT}  Thanks for learning with Kenilith Cloudx${NO_COLOR}"
echo -e "${RED_TEXT}  Subscribe for more Google Cloud Labs :${NO_COLOR}"
echo -e "${BLUE_TEXT}  https://www.youtube.com/@KenilithCloudx${NO_COLOR}"
echo ""
