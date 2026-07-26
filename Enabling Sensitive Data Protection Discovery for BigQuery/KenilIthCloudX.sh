#!/bin/bash
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Get the Project ID
echo "${BOLD}${GREEN}Fetching Project ID...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

# Step 2: Get the Project Number
echo "${BOLD}${CYAN}Fetching Project Number...${RESET}"
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")

# Step 3: Create a Tag Key
echo "${BOLD}${YELLOW}Creating Tag Key 'sensitivity-level'...${RESET}"
gcloud resource-manager tags keys create sensitivity-level \
    --parent=projects/$PROJECT_NUMBER \
    --description="Sensitivity level tagged as low, moderate, high, and unknown"

# Step 4: Get the Tag Key ID
echo "${BOLD}${BLUE}Fetching Tag Key ID...${RESET}"
TAG_KEY_ID=$(gcloud resource-manager tags keys list --parent="projects/${PROJECT_NUMBER}" --format="value(NAME)")

# Step 5: Create Tag Value 'low'
echo "${BOLD}${MAGENTA}Creating Tag Value 'low'...${RESET}"
gcloud resource-manager tags values create low \
    --parent=$TAG_KEY_ID \
    --description="Tag value to attach to low-sensitivity data"

# Step 6: Create Tag Value 'moderate'
echo "${BOLD}${RED}Creating Tag Value 'moderate'...${RESET}"
gcloud resource-manager tags values create moderate \
    --parent=$TAG_KEY_ID \
    --description="Tag value to attach to moderate-sensitivity data"

# Step 7: Create Tag Value 'high'
echo "${BOLD}${GREEN}Creating Tag Value 'high'...${RESET}"
gcloud resource-manager tags values create high \
    --parent=$TAG_KEY_ID \
    --description="Tag value to attach to high-sensitivity data"

# Step 8: Create Tag Value 'unknown'
echo "${BOLD}${CYAN}Creating Tag Value 'unknown'...${RESET}"
gcloud resource-manager tags values create unknown \
    --parent=$TAG_KEY_ID \
    --description="Tag value to attach to resources with an unknown sensitivity level"

sleep 10

# Step 9: Assign IAM policy for tags
echo "${BOLD}${YELLOW}Assigning IAM policy to allow tagging...${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:service-$PROJECT_NUMBER@dlp-api.iam.gserviceaccount.com --role=roles/resourcemanager.tagUser

echo
echo -e "\n"  # Adding one blank line

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
