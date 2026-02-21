# 🌏Respond to a Security Incident

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
gcloud compute firewall-rules delete critical-fw-rule --quiet 2>/dev/null; gcloud compute firewall-rules create critical-fw-rule --network=client-vpc --direction=INGRESS --priority=1000 --action=DENY --rules=tcp:80,tcp:22 --target-tags=compromised-vm --enable-logging; gcloud compute firewall-rules delete allow-ssh-from-bastion --quiet 2>/dev/null; gcloud compute firewall-rules create allow-ssh-from-bastion --network=client-vpc --action=allow --direction=ingress --rules=tcp:22 --source-ranges=$(gcloud compute instances describe bastion-host --zone=$(gcloud compute instances list --filter="name=bastion-host" --format="get(zone)") --format="get(networkInterfaces[0].accessConfigs[0].natIP)") --target-tags=compromised-vm; gcloud compute networks subnets update my-subnet --region=$(gcloud compute networks subnets list --filter="name=my-subnet" --format="get(region)") --enable-flow-logs
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
