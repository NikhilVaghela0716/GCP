#!/bin/bash

# ====================================================
# COLOR & FORMATTING DEFINITIONS
# ====================================================
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# ====================================================
# HEADER
# ====================================================
clear
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}           GOOGLE CLOUD REST API LAB | EXECUTION STARTED          ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo

# ====================================================
# STEP 1: CONFIGURATION
# ====================================================
echo "${BLUE}${BOLD}Step 1: Configuring Compute Zone...${RESET}"

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

echo "${BLUE}Zone selected: ${ZONE}${RESET}"
echo

# ====================================================
# STEP 2: ENABLE API
# ====================================================
echo "${BLUE}${BOLD}Step 2: Enabling Compute Engine API...${RESET}"

gcloud services enable compute.googleapis.com

echo "${BLUE}Waiting 15 seconds for API to propagate...${RESET}"
sleep 15
echo

# ====================================================
# STEP 3: CREATE VM (REST API)
# ====================================================
echo "${BLUE}${BOLD}Step 3: Creating VM Instance 'instance-1' via REST API...${RESET}"

# Using curl to hit the API directly as per lab requirements
curl -X POST "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"instance-1\",
    \"machineType\": \"zones/$ZONE/machineTypes/n1-standard-1\",
    \"networkInterfaces\": [{}],
    \"disks\": [{
      \"type\": \"PERSISTENT\",
      \"boot\": true,
      \"initializeParams\": {
        \"sourceImage\": \"projects/debian-cloud/global/images/family/debian-11\"
      }
    }]
  }"

echo
echo "${RED}VM Creation request sent.${RESET}"

# ====================================================
# CHECK PROGRESS
# ====================================================
function check_progress {
    while true; do
        echo
        echo -n "${RED}${BOLD}Have you checked your progress for Task 2? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BLUE}${BOLD}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${RED}${BOLD}Please check your progress for Task 2 and then press Y to continue.${RESET}"
        else
            echo
            echo "${RED}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

check_progress

# ====================================================
# STEP 4: DELETE VM (REST API)
# ====================================================
echo "${BLUE}${BOLD}Step 4: Deleting VM Instance 'instance-1'...${RESET}"

curl -X DELETE \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/instance-1"

echo
echo "${RED}VM Deletion request sent.${RESET}"
echo

# ====================================================
# CLEANUP
# ====================================================
echo "${BLUE}${BOLD}Performing cleanup...${RESET}"
cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with specific prefixes
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            if [[ -f "$file" ]]; then
                rm "$file"
                echo "${BLUE}File removed: $file${RESET}"
            fi
        fi
    done
}

remove_files

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
