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
echo "${BLUE_TEXT}${BOLD_TEXT}      CLOUD BUILD TRIGGERS LAB | EXECUTION STARTED                ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ====================================================
# STEP 1: CREATE REPOSITORY LINK
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 1: Linking GitHub Repository to Cloud Build...${RESET_FORMAT}"

gcloud builds repositories create cloudrun-progression \
    --remote-uri="https://github.com/${GITHUB_USERNAME}/cloudrun-progression.git" \
    --connection="cloud-build-connection" --region=$REGION

echo "${BLUE_TEXT}Repository link established.${RESET_FORMAT}"
echo

# ====================================================
# STEP 2: BRANCH TRIGGER (FEATURE)
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 2: Creating Branch Trigger...${RESET_FORMAT}"

gcloud builds triggers create github --name="branch" \
   --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/cloudrun-progression \
   --build-config='branch-cloudbuild.yaml' \
   --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
   --region=$REGION \
   --branch-pattern='[^(?!.*master)].*'

echo "${BLUE_TEXT}Trigger 'branch' created.${RESET_FORMAT}"
echo



# ====================================================
# STEP 3: FEATURE DEVELOPMENT WORKFLOW
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Simulating Feature Development (v1.1)...${RESET_FORMAT}"

echo "${BLUE_TEXT}Creating new branch 'new-feature-1'...${RESET_FORMAT}"
git checkout -b new-feature-1

echo "${BLUE_TEXT}Updating app version...${RESET_FORMAT}"
sed -i "s/v1.0/v1.1/g" app.py

echo "${BLUE_TEXT}Pushing changes to trigger build...${RESET_FORMAT}"
git add . && git commit -m "updated" && git push gcp new-feature-1

echo "${BLUE_TEXT}Retrieving Service URL...${RESET_FORMAT}"
# Note: This might take a moment to appear in a real scenario
BRANCH_URL=$(gcloud run services describe hello-cloudrun --platform managed --region $REGION --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"new-feature-1\")|.url")
echo "${RED_TEXT}Branch URL: $BRANCH_URL${RESET_FORMAT}"
echo

# ====================================================
# STEP 4: MASTER TRIGGER (CANARY)
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 4: Creating Master Trigger...${RESET_FORMAT}"

gcloud builds triggers create github --name="master" \
   --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/cloudrun-progression \
   --build-config='master-cloudbuild.yaml' \
   --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com  \
   --region=$REGION \
   --branch-pattern='master'

echo "${BLUE_TEXT}Trigger 'master' created.${RESET_FORMAT}"
echo

# ====================================================
# STEP 5: MERGE TO MASTER
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 5: Merging Feature to Master...${RESET_FORMAT}"

git checkout master
git merge new-feature-1
git push gcp master

echo "${BLUE_TEXT}Changes pushed to master. Waiting for Canary deployment...${RESET_FORMAT}"
CANARY_URL=$(gcloud run services describe hello-cloudrun --platform managed --region $REGION --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"canary\")|.url")
echo "${RED_TEXT}Canary URL: $CANARY_URL${RESET_FORMAT}"

echo "${BLUE_TEXT}Testing Canary Endpoint...${RESET_FORMAT}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $CANARY_URL
echo

# ====================================================
# STEP 6: TAG TRIGGER (PRODUCTION)
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 6: Creating Tag Trigger...${RESET_FORMAT}"

gcloud builds triggers create github --name="tag" \
   --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/cloudrun-progression \
   --build-config='tag-cloudbuild.yaml' \
   --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com  \
   --region=$REGION \
   --tag-pattern='.*'

echo "${BLUE_TEXT}Trigger 'tag' created.${RESET_FORMAT}"
echo

# ====================================================
# STEP 7: RELEASE WORKFLOW
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 7: Creating Release Tag (v1.1)...${RESET_FORMAT}"

git tag 1.1
git push gcp 1.1

echo "${BLUE_TEXT}Tag pushed. Production deployment triggered.${RESET_FORMAT}"

# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}         ✅ LAB COMPLETED SUCCESSFULLY!                       ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
