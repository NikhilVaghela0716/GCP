#!/bin/bash

# Define color variables
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# =========================
# WELCOME MESSAGE
# =========================
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}            🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀             ${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

echo
echo -e "${BLUE}Initializing Google Cloud Storage Lab environment...${NC}"
echo

read -p "Enter region: " USER_REGION

# Validate region input
if [ -z "$USER_REGION" ]; then
    echo -e "${RED}Warning: No region provided. Falling back to default region.${NC}"
    USER_REGION="us-central1"
fi

echo -e "${BLUE}Region selected: $USER_REGION${NC}"
echo

# Set project
echo -e "${BLUE}Applying Google Cloud project configuration...${NC}"
gcloud config set project $DEVSHELL_PROJECT_ID
echo -e "${BLUE}Active project is now: $DEVSHELL_PROJECT_ID${NC}"

# Clone repository
echo -e "${BLUE}Fetching training repository from GitHub...${NC}"
git clone https://github.com/GoogleCloudPlatform/training-data-analyst

# Navigate to directory
cd ~/training-data-analyst/courses/developingapps/python/cloudstorage/start

# Update region in configuration
echo -e "${BLUE}Applying region [$USER_REGION] to environment configuration...${NC}"
sed -i s/us-central/$USER_REGION/g prepare_environment.sh

# Prepare environment
echo -e "${BLUE}Bootstrapping the application environment...${NC}"
. prepare_environment.sh

# Create Cloud Storage bucket
echo -e "${BLUE}Provisioning a new Cloud Storage bucket...${NC}"
gsutil mb -l $USER_REGION gs://$DEVSHELL_PROJECT_ID-media

# Download and upload sample image
echo -e "${BLUE}Retrieving sample image and pushing it to the bucket...${NC}"
wget https://storage.googleapis.com/cloud-training/quests/Google_Cloud_Storage_logo.png
gsutil cp Google_Cloud_Storage_logo.png gs://$DEVSHELL_PROJECT_ID-media

# Set environment variable
export GCLOUD_BUCKET=$DEVSHELL_PROJECT_ID-media
echo -e "${BLUE}Bucket name exported: $GCLOUD_BUCKET${NC}"
echo -e "${BLUE}Bucket deployed in region: $USER_REGION${NC}"

# Navigate to GCP directory
cd quiz/gcp

# Create storage.py with Cloud Storage integration
echo -e "${BLUE}Writing Cloud Storage integration into storage.py...${NC}"
cat > storage.py <<EOF_END
# TODO: Import os to access environment variables
import os
# END TODO
# TODO: Get the Bucket name from the
# GCLOUD_BUCKET environment variable
bucket_name = os.getenv('GCLOUD_BUCKET')
# END TODO
# TODO: Import the storage module
from google.cloud import storage
# END TODO
# TODO: Create a client for Cloud Storage
storage_client = storage.Client()
# END TODO
# TODO: Use the client to get the Cloud Storage bucket
bucket = storage_client.get_bucket(bucket_name)
# END TODO

"""
Uploads a file to a given Cloud Storage bucket and returns the public url
to the new object.
"""
def upload_file(image_file, public):
    # TODO: Use the bucket to get a blob object
    blob = bucket.blob(image_file.filename)
    # END TODO
    # TODO: Use the blob to upload the file
    blob.upload_from_string(
        image_file.read(),
        content_type=image_file.content_type)
    # END TODO
    # TODO: Make the object public
    if public:
        blob.make_public()
    # END TODO
    # TODO: Modify to return the blob's Public URL
    return blob.public_url
    # END TODO
EOF_END

# Navigate to webapp directory
cd ../webapp/

# Create questions.py with file upload functionality
echo -e "${BLUE}Writing file upload logic into questions.py...${NC}"
cat > questions.py <<EOF_END
# TODO: Import the storage module
from quiz.gcp import storage, datastore
# END TODO
"""
uploads file into google cloud storage
- upload file
- return public_url
"""
def upload_file(image_file, public):
    if not image_file:
        return None
    # TODO: Use the storage client to Upload the file
    # The second argument is a boolean
    public_url = storage.upload_file(
       image_file,
       public
    )
    # END TODO
    # TODO: Return the public URL
    # for the object
    return public_url
    # END TODO
"""
uploads file into google cloud storage
- call method to upload file (public=true)
- call datastore helper method to save question
"""
def save_question(data, image_file):
    # TODO: If there is an image file, then upload it
    # And assign the result to a new Datastore
    # property imageUrl
    # If there isn't, assign an empty string
    if image_file:
        data['imageUrl'] = str(
                  upload_file(image_file, True))
    else:
        data['imageUrl'] = u''
    # END TODO
    data['correctAnswer'] = int(data['correctAnswer'])
    datastore.save_question(data)
    return

EOF_END

# Navigate back to start directory
cd ~/training-data-analyst/courses/developingapps/python/cloudstorage/start

# Display configuration summary
echo
echo -e "${RED}=== Configuration Summary ===${NC}"
echo -e "${BLUE}Project ID    : $DEVSHELL_PROJECT_ID${NC}"
echo -e "${BLUE}Region        : $USER_REGION${NC}"
echo -e "${BLUE}Storage Bucket: $GCLOUD_BUCKET${NC}"
echo -e "${RED}=================================${NC}"
echo

# Start the application server
echo -e "${BLUE}Launching the application server now...${NC}"
echo -e "${BLUE}Cloud Storage integration is active and ready!${NC}"
echo -e "${RED}Server is starting — hit Ctrl+C whenever you wish to stop it.${NC}"
echo
python run_server.py

# =========================
# COMPLETION FOOTER
# =========================
echo -e "${RED}==================================================================${NC}"
echo -e "${RED}                  LAB COMPLETED SUCCESSFULLY !                   ${NC}"
echo -e "${RED}==================================================================${NC}"
echo ""
echo -e "${BLUE}  Thanks for learning with Kenilith Cloudx${NC}"
echo -e "${RED}  Subscribe for more Google Cloud Labs :${NC}"
echo -e "${BLUE}  https://www.youtube.com/@KenilithCloudx${NC}"
echo ""
