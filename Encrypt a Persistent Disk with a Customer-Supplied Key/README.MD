# 🥳Encrypt a Persistent Disk with a Customer-Supplied Key 

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```bash
export PROJECT_ID=$(gcloud config get-value project) ZONE=$(gcloud compute instances list --limit=1 --format="value(zone)") VM_NAME=$(gcloud compute instances list --limit=1 --format="value(name)") BASE64_KEY=$(head -c 32 /dev/urandom | base64)
gcloud compute disks create csek-encrypted-disk --size=200GB --zone=$ZONE --csek-key-file=<(echo "[{\"uri\": \"https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/zones/$ZONE/disks/csek-encrypted-disk\", \"key\": \"$BASE64_KEY\", \"key-type\": \"raw\"}]")
gcloud compute instances attach-disk $VM_NAME --disk=csek-encrypted-disk --zone=$ZONE --csek-key-file=<(echo "[{\"uri\": \"https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/zones/$ZONE/disks/csek-encrypted-disk\", \"key\": \"$BASE64_KEY\", \"key-type\": \"raw\"}]")
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
