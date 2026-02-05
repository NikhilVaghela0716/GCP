# 🚀 Manage Rendering for Cloud Storage Website Hosting 

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```bash
export BUCKET=
```

```bash
PROJECT=$(gcloud config get-value project) && \
gsutil setmeta -h "Content-Type:text/html" gs://${BUCKET}/index.html && \
gsutil setmeta -h "Content-Type:text/css" gs://${BUCKET}/style.css && \
gsutil setmeta -h "Content-Type:image/jpeg" gs://${BUCKET}/logo.jpg && \
gsutil web set -m index.html -e 404.html gs://${BUCKET} && \
gsutil iam ch allUsers:objectViewer gs://${BUCKET}
```

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
