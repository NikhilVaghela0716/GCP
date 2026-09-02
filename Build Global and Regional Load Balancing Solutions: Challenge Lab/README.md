# 🥳Build Global and Regional Load Balancing Solutions: Challenge Lab | GSP539

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

### 1. Create Regional MIG

Go to:
Compute Engine → Instance Groups → Create Instance Group

- Name: mig-proxy-internal
- Template: template-proxy-internal
- Region: Region B

Add Named Port:
- tcp80 → 80

---

### 2. Create Firewall Rules

Go to:
VPC Network → Firewall

Rule 1:
```
gcloud compute firewall-rules create fw-allow-hc-proxy-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80
```

Rule 2:
```
gcloud compute firewall-rules create fw-allow-proxy-subnet-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=10.129.0.0/23 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80
```
---

### 3. Create Health Check
```
read -p "Enter REGION_A: " REGION_A
read -p "Enter REGION_B: " REGION_B

echo "export REGION_A=$REGION_A" >> ~/.bashrc
echo "export REGION_B=$REGION_B" >> ~/.bashrc

source ~/.bashrc

gcloud compute health-checks create tcp hc-internal-proxy \
    --region=$REGION_B \
    --port=80
```
---

### 4. Reserve Internal Static IP

Go to:
VPC Network → IP Addresses → Reserve Internal

Create:
- Name: ip-internal-proxy
- Region: Region B
- Network: lb-network
- Subnet: lb-backend-subnet-region-b
- Purpose: Shared Load Balancer VIP

---

### 5. Create Regional Internal Proxy Network Load Balancer

```
gcloud compute backend-services create internal-proxy-backend \
    --load-balancing-scheme=INTERNAL_MANAGED \
    --protocol=TCP \
    --region=$REGION_B \
    --health-checks=hc-internal-proxy \
    --health-checks-region=$REGION_B

gcloud compute backend-services add-backend internal-proxy-backend \
    --instance-group=mig-proxy-internal \
    --instance-group-region=$REGION_B \
    --region=$REGION_B
```
Frontend:
- Name: rule-internal-proxy
- IP Address: ip-internal-proxy
- Protocol: TCP
- Port: 110
- Global Access: Disabled

Create the Load Balancer.
---

### 6. Create Client VM
```
gcloud compute instances create vm-client-internal \
   --zone=${REGION_B}-b \
   --machine-type=e2-micro \
   --network=lb-network \
   --subnet=lb-backend-subnet-region-b \
   --tags=allow-ssh
```
---

### 7. Validate Access

SSH into vm-client-internal

Test:
```
# Get Internal LB IP
LB_IP=$(gcloud compute addresses describe ip-internal-proxy \
    --region=$REGION_B \
    --format="value(address)")

echo $LB_IP
```
Run in SSH
```
curl http://[LB_IP]:110
```
```bash
curl -LO "https://raw.githubusercontent.com/NikhilVaghela0716/GCP/main/Build%20Global%20and%20Regional%20Load%20Balancing%20Solutions%3A%20Challenge%20Lab/KenilithCloudX1.sh" && chmod +x KenilithCloudX1.sh && ./KenilithCloudX1.sh
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---
## 📺 Subscribe for More!

| [![Kenilith Cloudx](https://img.shields.io/badge/YouTube-Kenilith%20Cloudx-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@KenilithCloudx) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
