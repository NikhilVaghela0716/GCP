# 🚀 Configure Cloud Storage Bucket for Website Hosting using gsutil

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:


``bash
export BUCKET=
```
```bash
gsutil web set -m index.html -e error.html gs://$BUCKET && gsutil uniformbucketlevelaccess set off gs://$BUCKET && gsutil defacl set public-read gs://$BUCKET && gsutil acl set -a public-read gs://$BUCKET/index.html && gsutil acl set -a public-read gs://$BUCKET/error.html && gsutil acl set -a public-read gs://$BUCKET/style.css && gsutil acl set -a public-read gs://$BUCKET/logo.jpg
```

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
