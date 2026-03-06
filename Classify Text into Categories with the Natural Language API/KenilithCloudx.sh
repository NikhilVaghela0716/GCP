#!/bin/bash

# Define color variables
RED='\033[0;91m'
BLUE='\033[0;94m'

NC='\033[0m' # No Color
BOLD='\033[1m'
UNDERLINE='\033[4m'

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${NC}"
echo "${BLUE}${BOLD}            🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀               ${NC}"
echo "${BLUE}${BOLD}==================================================================${NC}"

clear

section() {
    echo -e "\n${RED}${BOLD}${1}${NC}"
}

# Get API key
section "Configuration Setup"
echo -e "${BLUE}Enter API Key : ${NC}"
read -p "$(echo -e "${RED}${BOLD}➤ API Key: ${NC}")" KEY
export KEY

# Enable API
section "Enabling Natural Language API"
echo -e "${BLUE}› Enabling the API${NC}"
gcloud services enable language.googleapis.com

# Zone information
section "Fetching Instance Information"
echo -e "${BLUE}› Retrieving Instance zone...${NC}"
ZONE="$(gcloud compute instances list --project=$DEVSHELL_PROJECT_ID --format='value(ZONE)')"

# Add metadata
section "Configuring Instance Metadata"
echo -e "${BLUE}› Adding API key to instance metadata${NC}"
gcloud compute instances add-metadata linux-instance \
    --metadata API_KEY="$KEY" \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE

# Create script
section "Creating Analysis Script"
echo -e "${BLUE}› Generating prepare_disk.sh script${NC}"
cat > prepare_disk.sh <<'EOF'
#!/bin/bash

# Get API key from metadata
API_KEY=$(curl -H "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/instance/attributes/API_KEY)

export API_KEY="$API_KEY"

# Create request JSON
cat > request.json <<'REQUEST_EOF'
{
    "document":{
        "type":"PLAIN_TEXT",
        "content":"A Smoky Lobster Salad With a Tapa Twist. This spin on the Spanish pulpo a la gallega skips the octopus, but keeps the sea salt, olive oil, pimentón and boiled potatoes."
    }
}
REQUEST_EOF

# Make API call
echo "Analyzing text content..."
curl "https://language.googleapis.com/v1/documents:classifyText?key=${API_KEY}" \
    -s -X POST -H "Content-Type: application/json" --data-binary @request.json

# Save results
curl "https://language.googleapis.com/v1/documents:classifyText?key=${API_KEY}" \
    -s -X POST -H "Content-Type: application/json" --data-binary @request.json > result.json

echo "Analysis complete. Results saved to result.json"
EOF

# Transfer script
section "Transferring Script to Instance"
echo -e "${BLUE}› Copying script to compute instance${NC}"
gcloud compute scp prepare_disk.sh linux-instance:/tmp \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --quiet

# Execute script
section "Executing Text Analysis"
echo -e "${BLUE}› Running analysis on compute instance${NC}"
gcloud compute ssh linux-instance \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --quiet \
    --command="export API_KEY=$KEY && bash /tmp/prepare_disk.sh"

# BigQuery setup
section "Configuring BigQuery"
echo -e "${BLUE}› Creating dataset for classification results${NC}"
bq --location=US mk --dataset $DEVSHELL_PROJECT_ID:news_classification_dataset

echo -e "${BLUE}› Creating table structure${NC}"
bq mk --table $DEVSHELL_PROJECT_ID:news_classification_dataset.article_data \
    article_text:STRING,category:STRING,confidence:FLOAT


# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED}${BOLD}==============================================================${NC}"
echo "${RED}${BOLD}                LAB COMPLETED SUCCESSFULLY!                ${NC}"
echo "${RED}${BOLD}==============================================================${NC}"
echo
echo "${BLUE}${BOLD}🙏 Thanks for learning with Kenilith Cloudx${NC}"
echo "${RED}${BOLD}📢 Subscribe for more Google Cloud Labs:${NC}"
echo "${BLUE}${BOLD}https://www.youtube.com/@KenilithCloudx${NC}"
echo
