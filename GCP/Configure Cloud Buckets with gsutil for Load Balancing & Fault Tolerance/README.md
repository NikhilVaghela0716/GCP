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
gcloud storage buckets create gs://$NEW_BUCKET --location=$REGION
gcloud storage buckets add-iam-policy-binding gs://$NEW_BUCKET --member=allUsers --role=roles/storage.objectViewer
gcloud storage rsync -r gs://$OLD_BUCKET gs://$NEW_BUCKET
gcloud storage buckets update gs://$NEW_BUCKET --web-main-page-suffix=index.html
gcloud compute backend-buckets create web-backend --gcs-bucket-name=$NEW_BUCKET
gcloud compute url-maps create web-map --default-backend-bucket=web-backend
gcloud compute target-http-proxies create web-proxy --url-map=web-map
gcloud compute forwarding-rules create web-rule --load-balancing-scheme=EXTERNAL --target-http-proxy=web-proxy --ports=80 --global
gcloud compute forwarding-rules list
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
