# Configure Firewall Rule to Allow HTTP Traffic for Web Server
---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```bash
FIREWALL_RULE="allow-http-rule"; ALLOWED_TRAFFIC="tcp:80"; SOURCE_RANGE="0.0.0.0/0"; TARGET_TAG="allow-http"; gcloud compute firewall-rules update "$FIREWALL_RULE" --allow="$ALLOWED_TRAFFIC" --source-ranges="$SOURCE_RANGE" --target-tags="$TARGET_TAG"
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
