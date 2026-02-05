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
# STEP 1: REGION CONFIGURATION
# ====================================================

# Loop until a valid region is provided
if [ -z "$region" ]; then
  while true; do
    echo "${RED_TEXT}${BOLD_TEXT}Enter your GCP region (e.g., us-central1):${RESET_FORMAT}"
    read region
    
    # Simple regex to validate region format (basic check)
    if [[ -z "$region" ]]; then
      echo "${RED_TEXT}Region cannot be empty. Please try again.${RESET_FORMAT}"
    elif [[ $region =~ ^[a-z]+-[a-z]+[0-9]+$ ]]; then
      export region
      echo "${BLUE_TEXT}Region set to: $region${RESET_FORMAT}"
      break
    else
      echo "${RED_TEXT}Invalid region format. Use format like 'us-central1'${RESET_FORMAT}"
    fi
  done
fi

export BUCKET=$(gcloud config get-value project)

# ====================================================
# STEP 2: BUCKET CREATION
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating bucket: gs://$BUCKET${RESET_FORMAT}"
gsutil mb -l $region "gs://$BUCKET"
sleep 5
echo "${RED_TEXT}Bucket created successfully.${RESET_FORMAT}"

# ====================================================
# STEP 3: RETENTION POLICY
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Setting 10-second retention policy...${RESET_FORMAT}"
gsutil retention set 10s "gs://$BUCKET"
gsutil retention get "gs://$BUCKET"
echo "${RED_TEXT}Retention policy applied.${RESET_FORMAT}"

# ====================================================
# STEP 4: UPLOAD FILE 1
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Uploading dummy_transactions file...${RESET_FORMAT}"
gsutil cp gs://spls/gsp297/dummy_transactions "gs://$BUCKET/"
gsutil ls -L "gs://$BUCKET/dummy_transactions"
sleep 5
echo "${RED_TEXT}File uploaded successfully.${RESET_FORMAT}"

# ====================================================
# STEP 5: LOCK RETENTION
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Locking retention policy...${RESET_FORMAT}"
echo "${BLUE_TEXT}Note: Once locked, the policy cannot be removed until retention expires.${RESET_FORMAT}"
gsutil retention lock "gs://$BUCKET/"
echo "${RED_TEXT}Retention policy locked.${RESET_FORMAT}"

# ====================================================
# STEP 6: TEMPORARY HOLD
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Setting temporary hold on file...${RESET_FORMAT}"
gsutil retention temp set "gs://$BUCKET/dummy_transactions"
echo "${RED_TEXT}Temporary hold applied.${RESET_FORMAT}"

# ====================================================
# STEP 7: VERIFY DELETION PROTECTION
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Attempting file deletion (This should fail)...${RESET_FORMAT}"
# We allow this command to fail and catch it visually
gsutil rm "gs://$BUCKET/dummy_transactions"
echo "${RED_TEXT}Expected error occurred (file protected by hold).${RESET_FORMAT}"

# ====================================================
# STEP 8: RELEASE HOLD
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Releasing temporary hold...${RESET_FORMAT}"
gsutil retention temp release "gs://$BUCKET/dummy_transactions"
echo "${RED_TEXT}Hold released successfully.${RESET_FORMAT}"

# ====================================================
# STEP 9: EVENT-BASED HOLD
# ====================================================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Setting event-based hold as default...${RESET_FORMAT}"
gsutil retention event-default set "gs://$BUCKET/"
echo "${RED_TEXT}Event-based hold configured.${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Uploading dummy_loan file...${RESET_FORMAT}"
gsutil cp gs://spls/gsp297/dummy_loan "gs://$BUCKET/"
gsutil ls -L "gs://$BUCKET/dummy_loan"
echo "${RED_TEXT}File uploaded successfully.${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Releasing event-based hold...${RESET_FORMAT}"
gsutil retention event release "gs://$BUCKET/dummy_loan"
gsutil ls -L "gs://$BUCKET/dummy_loan"
echo "${RED_TEXT}Event-based hold released.${RESET_FORMAT}"

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
