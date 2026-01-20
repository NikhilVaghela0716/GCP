# 🚀Configure Cloud Buckets with gsutil for Load Balancing & Fault Tolerance 

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```bash
export OLD_BUCKET=
export NEW_BUCKET=
export REGION=
```
```bash
gsutil mb -l $REGION gs://$NEW_BUCKET && gsutil rsync -r gs://$OLD_BUCKET gs://$NEW_BUCKET && gsutil iam ch allUsers:objectViewer gs://$NEW_BUCKET && gsutil web set -m index.html -e 404.html gs://$NEW_BUCKET && gcloud compute backend-buckets create web-backend --gcs-bucket-name=$NEW_BUCKET && gcloud compute url-maps create web-map --default-backend-bucket=web-backend && gcloud compute target-http-proxies create http-lb-proxy --url-map=web-map && gcloud compute forwarding-rules create http-content-rule --global --target-http-proxy=http-lb-proxy --ports=80 && gcloud compute forwarding-rules list
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
