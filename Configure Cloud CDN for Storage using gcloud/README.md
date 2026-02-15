# 🍾Configure Cloud CDN for Storage using gcloud
 
---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```bash
PROJECT_ID=$(gcloud config get-value project) && BUCKET_NAME="${PROJECT_ID}-bucket" && BACKEND_BUCKET="static-backend-bucket" && URL_MAP="cdn-map" && PROXY="cdn-http-proxy" && FORWARDING_RULE="cdn-http-rule" && gcloud compute backend-buckets create $BACKEND_BUCKET --gcs-bucket-name=$BUCKET_NAME --enable-cdn && gcloud compute url-maps create $URL_MAP --default-backend-bucket=$BACKEND_BUCKET && gcloud compute target-http-proxies create $PROXY --url-map=$URL_MAP && gcloud compute forwarding-rules create $FORWARDING_RULE --global --target-http-proxy=$PROXY --ports=80 && IP_ADDRESS=$(gcloud compute forwarding-rules describe $FORWARDING_RULE --global --format="value(IPAddress)") && gsutil ls gs://$BUCKET_NAME/images/ 
```
### `Wait for 1 Minutes`
```bash
curl -o nature.png http://$IP_ADDRESS/images/nature.png
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
