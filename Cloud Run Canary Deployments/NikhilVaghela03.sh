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
echo "${BLUE_TEXT}${BOLD_TEXT}      CLOUD BUILD TRIGGERS LAB | EXECUTION STARTED               ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

gcloud builds repositories create cloudrun-progression \
  --remote-uri="https://github.com/${GITHUB_USERNAME}/cloudrun-progression.git" \
  --connection="cloud-build-connection" \
  --region=$REGION

gcloud builds triggers create github --name="branch" \
  --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/cloudrun-progression \
  --build-config='branch-cloudbuild.yaml' \
  --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --region=$REGION \
  --branch-pattern='[^(?!.*master)].*'

git checkout -b new-feature-1

# ❌ INVALID BASH (belongs in app source code, not shell script)
# @app.route('/')
# def hello_world():
#     return 'Hello World v1.1'

git add .
git commit -m "updated"
git push gcp new-feature-1

BRANCH_URL=$(gcloud run services describe hello-cloudrun \
  --platform managed \
  --region $REGION \
  --format=json | jq --raw-output '.status.traffic[] | select(.tag=="new-feature-1") | .url')

echo "$BRANCH_URL"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$BRANCH_URL"

gcloud builds triggers create github --name="master" \
  --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/cloudrun-progression \
  --build-config='master-cloudbuild.yaml' \
  --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --region=$REGION \
  --branch-pattern='master'

git checkout master
git merge new-feature-1
git push gcp master

CANARY_URL=$(gcloud run services describe hello-cloudrun \
  --platform managed \
  --region $REGION \
  --format=json | jq --raw-output '.status.traffic[] | select(.tag=="canary") | .url')

echo "$CANARY_URL"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$CANARY_URL"

LIVE_URL=$(gcloud run services describe hello-cloudrun \
  --platform managed \
  --region $REGION \
  --format=json | jq --raw-output '.status.url')

for i in {0..20}; do
  curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$LIVE_URL"
  echo
done

gcloud builds triggers create github --name="tag" \
  --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/cloudrun-progression \
  --build-config='tag-cloudbuild.yaml' \
  --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --region=$REGION \
  --tag-pattern='.*'

git tag 1.1
git push gcp 1.1

# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}        ✅ LAB COMPLETED SUCCESSFULLY!                         ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
