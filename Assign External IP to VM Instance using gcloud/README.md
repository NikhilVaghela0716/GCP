# 🥳Assign External IP to VM Instance using gcloud

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```bash

export VM_NAME=$(gcloud compute instances list --format='value(name)' --limit=1) && export ZONE=$(gcloud compute instances list --format='value(zone)' --limit=1) && export REGION=${ZONE%-*}
gcloud compute addresses create lab-static-ip --region=$REGION
export IP_ADDRESS=$(gcloud compute addresses describe lab-static-ip --region=$REGION --format='get(address)') && gcloud compute instances add-access-config $VM_NAME --zone=$ZONE --address=$IP_ADDRESS
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Kenilith Cloudx](https://img.shields.io/badge/YouTube-Kenilith%20Cloudx-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@KenilithCloudx) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
