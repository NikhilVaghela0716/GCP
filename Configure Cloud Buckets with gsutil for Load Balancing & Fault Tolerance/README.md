# 🚀Configure Cloud Buckets with gsutil for Load Balancing & Fault Tolerance 

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```bash
PROJECT_ID=$(gcloud config get-value project) && OLD_BUCKET=${PROJECT_ID}-bucket && NEW_BUCKET=${PROJECT_ID}-new && gsutil mb gs://$NEW_BUCKET && gsutil web set -m index.html -e error.html gs://$NEW_BUCKET && gsutil iam ch allUsers:roles/storage.admin gs://$NEW_BUCKET && gsutil -m rsync -r gs://$OLD_BUCKET gs://$NEW_BUCKET && gcloud compute backend-buckets create backend-new --gcs-bucket-name=$NEW_BUCKET --enable-cdn && gcloud compute url-maps create website-map --default-backend-bucket=backend-new && gcloud compute target-http-proxies create website-proxy --url-map=website-map && gcloud compute forwarding-rules create website-rule --global --target-http-proxy=website-proxy --ports=80 && gcloud compute forwarding-rules list
```


---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
