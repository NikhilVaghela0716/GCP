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
# WELCOME MESSAGE
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}           GOOGLE CLOUD & GITHUB LAB | EXECUTION STARTED          ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ====================================================
# STEP 1: GITHUB REPO SETUP
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 1: Creating Private GitHub Repository...${RESET_FORMAT}"

gh repo create cloudrun-progression --private 

echo "${BLUE_TEXT}Repository 'cloudrun-progression' created.${RESET_FORMAT}"
echo

# ====================================================
# STEP 2: CLONE TRAINING DATA
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 2: Cloning Training Data Repository...${RESET_FORMAT}"

git clone https://github.com/GoogleCloudPlatform/training-data-analyst

echo "${BLUE_TEXT}Setting up local progression folder...${RESET_FORMAT}"
mkdir -p cloudrun-progression
cp -r /home/$USER/training-data-analyst/self-paced-labs/cloud-run/canary/* cloudrun-progression/
cd cloudrun-progression

# ====================================================
# STEP 3: CONFIGURE CLOUDBUILD YAMLS
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Updating Cloud Build YAMLs with Region: $REGION...${RESET_FORMAT}"

sed -i "s/_REGION: us-central1/_REGION: $REGION/g" branch-cloudbuild.yaml
sed -i "s/_REGION: us-central1/_REGION: $REGION/g" master-cloudbuild.yaml
sed -i "s/_REGION: us-central1/_REGION: $REGION/g" tag-cloudbuild.yaml

echo "${BLUE_TEXT}YAML files updated.${RESET_FORMAT}"
echo

# ====================================================
# STEP 4: CONFIGURE TRIGGER JSONS
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 4: Updating Trigger JSONs with Project ID and Number...${RESET_FORMAT}"

sed -e "s/PROJECT/${PROJECT_ID}/g" -e "s/NUMBER/${PROJECT_NUMBER}/g" branch-trigger.json-tmpl > branch-trigger.json
sed -e "s/PROJECT/${PROJECT_ID}/g" -e "s/NUMBER/${PROJECT_NUMBER}/g" master-trigger.json-tmpl > master-trigger.json
sed -e "s/PROJECT/${PROJECT_ID}/g" -e "s/NUMBER/${PROJECT_NUMBER}/g" tag-trigger.json-tmpl > tag-trigger.json

echo "${BLUE_TEXT}JSON templates converted.${RESET_FORMAT}"
echo

# ====================================================
# STEP 5: INITIAL GIT COMMIT & PUSH
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 5: Initializing Git and Pushing to Master...${RESET_FORMAT}"

git init
git config credential.helper gcloud.sh
git remote add gcp https://github.com/${GITHUB_USERNAME}/cloudrun-progression
git branch -m master
git add . && git commit -m "initial commit"
git push gcp master

echo "${BLUE_TEXT}Code pushed to GitHub successfully.${RESET_FORMAT}"
echo

# ====================================================
# STEP 6: BUILD & DEPLOY TO CLOUD RUN
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 6: Building Image and Deploying to Cloud Run...${RESET_FORMAT}"

gcloud builds submit --tag gcr.io/$PROJECT_ID/hello-cloudrun

gcloud run deploy hello-cloudrun \
--image gcr.io/$PROJECT_ID/hello-cloudrun \
--platform managed \
--region $REGION \
--tag=prod -q



# ====================================================
# STEP 7: TEST PROD URL
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 7: Testing Production URL...${RESET_FORMAT}"

PROD_URL=$(gcloud run services describe hello-cloudrun --platform managed --region $REGION --format=json | jq --raw-output ".status.url")

echo "${RED_TEXT}Production URL: $PROD_URL${RESET_FORMAT}"

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $PROD_URL
echo

# ====================================================
# STEP 8: CLOUD BUILD GITHUB CONNECTION
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 8: Creating Cloud Build GitHub Connection...${RESET_FORMAT}"

gcloud builds connections create github cloud-build-connection --project=$PROJECT_ID  --region=$REGION 

echo "${BLUE_TEXT}Verifying connection...${RESET_FORMAT}"
gcloud builds connections describe cloud-build-connection --region=$REGION 

# ====================================================
# FINAL WARNING
# ====================================================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT} Follow the video and don’t run commands without watching it. ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
