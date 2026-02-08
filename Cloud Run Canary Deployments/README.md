# 🥳Cloud Run Canary Deployments | GSP1078

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

### `1`
```bash
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
gcloud config set compute/region $REGION


gcloud services enable \
cloudresourcemanager.googleapis.com \
container.googleapis.com \
cloudbuild.googleapis.com \
containerregistry.googleapis.com \
run.googleapis.com \
secretmanager.googleapis.com

sleep 60


gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com \
--role=roles/secretmanager.admin


curl -sS https://webi.sh/gh | sh
gh auth login
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo ${GITHUB_USERNAME}
echo ${USER_EMAIL}

```

### `2`
```bash

gh repo create cloudrun-progression --private 

git clone https://github.com/GoogleCloudPlatform/training-data-analyst

mkdir cloudrun-progression
cp -r /home/$USER/training-data-analyst/self-paced-labs/cloud-run/canary/*  cloudrun-progression
cd cloudrun-progression

sed -i "s/_REGION: us-central1/_REGION: $REGION/g" branch-cloudbuild.yaml
sed -i "s/_REGION: us-central1/_REGION: $REGION/g" master-cloudbuild.yaml
sed -i "s/_REGION: us-central1/_REGION: $REGION/g" tag-cloudbuild.yaml


sed -e "s/PROJECT/${PROJECT_ID}/g" -e "s/NUMBER/${PROJECT_NUMBER}/g" branch-trigger.json-tmpl > branch-trigger.json
sed -e "s/PROJECT/${PROJECT_ID}/g" -e "s/NUMBER/${PROJECT_NUMBER}/g" master-trigger.json-tmpl > master-trigger.json
sed -e "s/PROJECT/${PROJECT_ID}/g" -e "s/NUMBER/${PROJECT_NUMBER}/g" tag-trigger.json-tmpl > tag-trigger.json


git init
git config credential.helper gcloud.sh
git remote add gcp https://github.com/${GITHUB_USERNAME}/cloudrun-progression
git branch -m master
git add . && git commit -m "initial commit"
git push gcp master


gcloud builds submit --tag gcr.io/$PROJECT_ID/hello-cloudrun
gcloud run deploy hello-cloudrun \
--image gcr.io/$PROJECT_ID/hello-cloudrun \
--platform managed \
--region $REGION \
--tag=prod -q


PROD_URL=$(gcloud run services describe hello-cloudrun --platform managed --region $REGION --format=json | jq --raw-output ".status.url")
echo $PROD_URL
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $PROD_URL


gcloud builds connections create github cloud-build-connection --project=$PROJECT_ID  --region=$REGION 

gcloud builds connections describe cloud-build-connection --region=$REGION 


```

### `3`
```bash

gcloud builds repositories create cloudrun-progression \
     --remote-uri="https://github.com/${GITHUB_USERNAME}/cloudrun-progression.git" \
     --connection="cloud-build-connection" --region=$REGION


gcloud builds triggers create github --name="branch" \
   --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/cloudrun-progression \
   --build-config='branch-cloudbuild.yaml' \
   --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
   --region=$REGION \
   --branch-pattern='[^(?!.*master)].*'


git checkout -b new-feature-1


sed -i "s/v1.0/v1.1/g" app.py

git add . && git commit -m "updated" && git push gcp new-feature-1

BRANCH_URL=$(gcloud run services describe hello-cloudrun --platform managed --region $REGION --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"new-feature-1\")|.url")
echo $BRANCH_URL


gcloud builds triggers create github --name="master" \
   --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/cloudrun-progression \
   --build-config='master-cloudbuild.yaml' \
   --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com  \
   --region=$REGION \
   --branch-pattern='master'


git checkout master
git merge new-feature-1
git push gcp master


CANARY_URL=$(gcloud run services describe hello-cloudrun --platform managed --region $REGION --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"canary\")|.url")
echo $CANARY_URL

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $CANARY_URL




gcloud builds triggers create github --name="tag" \
   --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/cloudrun-progression \
   --build-config='tag-cloudbuild.yaml' \
   --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com  \
   --region=$REGION \
   --tag-pattern='.*'


git tag 1.1
git push gcp 1.1
```



---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
