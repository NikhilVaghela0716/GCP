# Analyze Sentiment with Natural Language API: Challenge Lab | ARC130

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```
export API_KEY=
```
```
curl -s -H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://language.googleapis.com/v1/documents:analyzeSyntax" \
-d @analyze-request.json > analyze-response.txt

```
---
```

curl -s -H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://language.googleapis.com/v1/documents:analyzeEntities" \
-d @multi-nl-request.json > multi-response.txt
```
---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---
## 📺 Subscribe for More!

| [![Kenilith Cloudx](https://img.shields.io/badge/YouTube-Kenilith%20Cloudx-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@KenilithCloudx) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
