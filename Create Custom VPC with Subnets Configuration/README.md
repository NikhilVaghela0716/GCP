# 🌏Create Custom VPC with Subnets Configuration

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```bash
gcloud compute networks delete custom-vpc -q && gcloud compute networks create custom-vpc --subnet-mode=custom -q && gcloud compute networks subnets create subnet-us --network=custom-vpc --region=us-central1 --range=10.0.1.0/24 -q && gcloud compute networks subnets create subnet-asia --network=custom-vpc --region=asia-southeast1 --range=10.0.2.0/24 -q
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
