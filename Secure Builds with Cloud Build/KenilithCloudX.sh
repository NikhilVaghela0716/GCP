#!/bin/bash
# Modern Color Definitions
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                  🚀 GOOGLE CLOUD LAB | KenilithCloudX            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

set -euo pipefail

echo "=================================================================="
echo " Step 0: Project setup"
echo "=================================================================="

export PROJECT_ID
PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER
PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" \
    --format='value(projectNumber)')

echo "PROJECT_ID:     ${PROJECT_ID}"
echo "PROJECT_NUMBER: ${PROJECT_NUMBER}"

echo "=================================================================="
echo " Step 1: Enable required APIs"
echo "=================================================================="

gcloud services enable \
  cloudkms.googleapis.com \
  cloudbuild.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  containerscanning.googleapis.com \
  ondemandscanning.googleapis.com \
  binaryauthorization.googleapis.com

echo "=================================================================="
echo " Step 2: Grant IAM roles to the Cloud Build service account"
echo "=================================================================="

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/ondemandscanning.admin"

echo "=================================================================="
echo " Step 3: Create sample app directory"
echo "=================================================================="

mkdir -p vuln-scan && cd vuln-scan

echo "=================================================================="
echo " Step 4: Write initial Dockerfile (uses older base image/deps)"
echo "=================================================================="

cat > ./Dockerfile << 'EOF'
FROM gcr.io/google-appengine/debian11

# System
RUN apt update && apt install python3-pip -y

# App
WORKDIR /app
COPY . ./

RUN pip3 install Flask==1.1.4
RUN pip3 install gunicorn==20.1.0

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
EOF

echo "=================================================================="
echo " Step 5: Write sample Flask app"
echo "=================================================================="

cat > ./main.py << 'EOF'
import os
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "Worlds")
    return "Hello {}!".format(name)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
EOF

echo "=================================================================="
echo " Step 6: Write initial cloudbuild.yaml (build only) and submit"
echo "=================================================================="

cat > ./cloudbuild.yaml << EOF
steps:

# build
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'us-central1-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']
EOF

gcloud builds submit

echo "=================================================================="
echo " Step 7: Create Artifact Registry repository"
echo "=================================================================="

gcloud artifacts repositories create artifact-scanning-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Docker repository"

gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

echo "=================================================================="
echo " Step 8: Update cloudbuild.yaml to build + push, then submit"
echo "=================================================================="

cat > ./cloudbuild.yaml << EOF
steps:

# build
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'us-central1-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']

# push to artifact registry
- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push',  'us-central1-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image']

images:
  - us-central1-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
EOF

gcloud builds submit

echo "=================================================================="
echo " Step 9: Local docker build (optional, mirrors Cloud Build step)"
echo "=================================================================="

docker build -t us-central1-docker.pkg.dev/"${PROJECT_ID}"/artifact-scanning-repo/sample-image .

echo "=================================================================="
echo " Step 10: Scan the image and list vulnerabilities"
echo "=================================================================="

gcloud artifacts docker images scan \
    us-central1-docker.pkg.dev/"${PROJECT_ID}"/artifact-scanning-repo/sample-image \
    --format="value(response.scan)" > scan_id.txt

gcloud artifacts docker images list-vulnerabilities "$(cat scan_id.txt)"

export SEVERITY=CRITICAL

if gcloud artifacts docker images list-vulnerabilities "$(cat scan_id.txt)" \
    --format="value(vulnerability.effectiveSeverity)" | grep -Fxq "${SEVERITY}"; then
  echo "Failed vulnerability check for ${SEVERITY} level"
else
  echo "No ${SEVERITY} Vulnerabilities found"
fi

echo "=================================================================="
echo " Step 11: Re-confirm IAM bindings (idempotent, safe to re-run)"
echo "=================================================================="

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/ondemandscanning.admin"

echo "=================================================================="
echo " Step 12: Full CI/CD pipeline with automated scan gate + retag"
echo "=================================================================="

cat > ./cloudbuild.yaml << EOF
steps:

# build
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'us-central1-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']

#Run a vulnerability scan at _SECURITY level
- id: scan
  name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
    (gcloud artifacts docker images scan \
    us-central1-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image \
    --location us \
    --format="value(response.scan)") > /workspace/scan_id.txt

#Analyze the result of the scan
- id: severity check
  name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
      gcloud artifacts docker images list-vulnerabilities \$(cat /workspace/scan_id.txt) \
      --format="value(vulnerability.effectiveSeverity)" | if grep -Fxq CRITICAL; \
      then echo "Failed vulnerability check for CRITICAL level" && exit 1; else echo "No CRITICAL vulnerability found, congrats !" && exit 0; fi

#Retag
- id: "retag"
  name: 'gcr.io/cloud-builders/docker'
  args: ['tag',  'us-central1-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', 'us-central1-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good']


#pushing to artifact registry
- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push',  'us-central1-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good']

images:
  - us-central1-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
EOF

gcloud builds submit

echo "=================================================================="
echo " Step 13: Rewrite Dockerfile with a hardened, updated base image"
echo "=================================================================="

cat > ./Dockerfile << 'EOF'
FROM python:3.12-alpine

# App
WORKDIR /app
COPY . ./

RUN pip3 install Flask==3.0.3
RUN pip3 install gunicorn==22.0.0
RUN pip3 install Werkzeug==3.0.3

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 main:app
EOF

echo "=================================================================="
echo " Step 14: Submit final hardened build"
echo "=================================================================="

gcloud builds submit

echo
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          		           ✅ LAB FINISHED!                         ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}🙏 Thank you for learning with KenilithCloudX!${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more hands-on Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
