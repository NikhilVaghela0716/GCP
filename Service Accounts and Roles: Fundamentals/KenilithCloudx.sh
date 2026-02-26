#!/bin/bash

# =========================
# COLOR DEFINITIONS (ONLY RED & BLUE)
# =========================
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀           ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

gcloud auth list

echo "${BLUE_TEXT}${BOLD_TEXT}Setting PROJECT_ID${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${RED_TEXT}${BOLD_TEXT}Project ID: $PROJECT_ID${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}Determining Default Compute Zone : ${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
echo "${RED_TEXT}${BOLD_TEXT}Zone: $ZONE${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}Determining Default Compute Region${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${RED_TEXT}${BOLD_TEXT}Region: $REGION${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}SERVICE ACCOUNT CONFIGURATION${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Creating service account : 'my-sa-123'${RESET_FORMAT}"
gcloud iam service-accounts create my-sa-123 \
  --display-name "Service Account for BigQuery Demo"

echo "${BLUE_TEXT}${BOLD_TEXT}Granting Editor role to 'my-sa-123'${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member serviceAccount:my-sa-123@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
  --role roles/editor

echo "${BLUE_TEXT}${BOLD_TEXT}Creating service account 'bigquery-qwiklab'${RESET_FORMAT}"
gcloud iam service-accounts create bigquery-qwiklab \
  --description="Service account for BigQuery operations" \
  --display-name="bigquery-qwiklab"

echo "${BLUE_TEXT}${BOLD_TEXT}Granting BigQuery roles${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataViewer"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.user"


echo "${BLUE_TEXT}${BOLD_TEXT}Creating Compute Engine instance${RESET_FORMAT}"
gcloud compute instances create bigquery-instance \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --service-account=bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --image-family=debian-11 \
  --image-project=debian-cloud

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Waiting for instance initialization.${RESET_FORMAT}"
sleep 20
echo "${RED_TEXT}${BOLD_TEXT}Instance is ready${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}Creating script 'cp_disk.sh'${RESET_FORMAT}"

cat > cp_disk.sh <<'EOF'
#!/bin/bash

sudo apt-get update -qq
sudo apt-get install -y -qq python3-pip

pip3 install --quiet google-cloud-bigquery pyarrow pandas db-dtypes

cat > query.py <<'EOF_PY'
from google.cloud import bigquery

client = bigquery.Client()

query = '''
SELECT
  year,
  COUNT(1) AS num_babies
FROM
  publicdata.samples.natality
WHERE
  year > 2000
GROUP BY year
ORDER BY year
'''

df = client.query(query).to_dataframe()
print(df.to_string(index=False))
EOF_PY

python3 query.py
EOF

echo "${RED_TEXT}${BOLD_TEXT}Script creation Done${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}Copying script to VM${RESET_FORMAT}"
gcloud compute scp cp_disk.sh bigquery-instance:/tmp \
  --zone=$ZONE --quiet

echo "${BLUE_TEXT}${BOLD_TEXT}Executing script on VM${RESET_FORMAT}"
gcloud compute ssh bigquery-instance \
  --zone=$ZONE \
  --command="chmod +x /tmp/cp_disk.sh && /tmp/cp_disk.sh" \
  --quiet

echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}           ✅ LAB COMPLETED SUCCESSFULLY!                     ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Kenilith Cloudx${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}📢 https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
