# 🥳Monitoring in Google Cloud: Challenge Lab | ARC115

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```bash
curl -LO https://raw.githubusercontent.com/NikhilVaghela0716/GCP/main/Monitoring%20in%20Google%20Cloud:%20Challenge%20Lab/KenilithCloudX.sh
sudo chmod +x KenilithCloudX.sh
./KenilithCloudX.sh
```

2. Paste The Following in vm (cloud shell)
```
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
```

3. Paste The Following in **Regular Expression**:
```
# Configures Ops Agent to collect telemetry from the app and restart Ops Agent.

set -e

# Create a back up of the existing file so existing configurations are not lost.
sudo cp /etc/google-cloud-ops-agent/config.yaml /etc/google-cloud-ops-agent/config.yaml.bak

# Configure the Ops Agent.
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null << EOF
metrics:
  receivers:
    apache:
      type: apache
  service:
    pipelines:
      apache:
        receivers:
          - apache
logging:
  receivers:
    apache_access:
      type: apache_access
    apache_error:
      type: apache_error
  service:
    pipelines:
      apache:
        receivers:
          - apache_access
          - apache_error
EOF

sudo service google-cloud-ops-agent restart
sleep 60
```
---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---
## 📺 Subscribe for More!

| [![Kenilith Cloudx](https://img.shields.io/badge/YouTube-Kenilith%20Cloudx-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@KenilithCloudx) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
