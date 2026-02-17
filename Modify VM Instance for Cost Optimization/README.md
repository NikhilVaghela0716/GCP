# 🌏Modify VM Instance for Cost Optimization

---

## ⚠️ Disclaimer

### Educational Purpose Only
This repository and its contents are provided **strictly for educational and learning purposes**. The materials are intended to help users understand Google Cloud lab services and support skill development for career growth.

### Review Before Use
Please review the scripts and documentation carefully before use to ensure you understand the relevant Google Cloud services and concepts.

These resources are meant to **enhance learning and understanding** and must not be used to bypass, automate, or misuse any platform features.

---

## 💻 Run in Cloud Shell:

```bash
INSTANCE=$(gcloud compute instances list --format="value(name)" | head -n 1) && ZONE=$(gcloud compute instances list --format="value(zone)" | head -n 1 | awk -F/ '{print $NF}') && gcloud compute instances stop $INSTANCE --zone=$ZONE && gcloud compute instances set-machine-type $INSTANCE --zone=$ZONE --machine-type=e2-medium && gcloud compute instances start [Instance_name] --zone=[YOUR_ZONE]
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Kenilith Cloudx](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@KenilithCloudx) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
