# 😎Multimodal Content Generation with Gemini on Vertex AI

---

## ⚠️ Disclaimer ⚠️

> **Educational Purpose Only:** This script and guide are provided for educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
>
> **Terms Compliance:** Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

---

## 💻 Run in Cloud Shell:

```bash
import vertexai
from vertexai.generative_models import GenerativeModel, Part

# -----------------------------
# CONFIG
# -----------------------------
# Replace these with the values from your Qwiklabs lab panel
PROJECT_ID = "YOUR_PROJECT_ID" 
LOCATION = "YOUR_REGION"

# Initialize Vertex AI
vertexai.init(project=PROJECT_ID, location=LOCATION)

def load_image_from_url(prompt):
    """
    Generates content using Gemini 2.0 Flash
    with image + text input.
    """
    # 1. Initialize the generative model
    model = GenerativeModel("gemini-2.0-flash")
    
    # 2. Load the image from Cloud Storage
    image = Part.from_uri(
        uri="gs://cloud-samples-data/vision/landmark/eiffel_tower.jpg",
        mime_type="image/jpeg"
    )
    
    # 3. Generate the response using both the image and the text prompt
    response = model.generate_content([image, prompt])
    
    return response.text

if __name__ == "__main__":
    prompt = "Describe this image in detail and explain what makes it unique."
    print("Prompt:", prompt)
    print("\nModel Response:\n")
    try:
        print(load_image_from_url(prompt))
    except Exception as e:
        print("Error:", e)
```

---

## 🎉 Congratulations! Lab Completed Successfully! 🏆

---

## 📺 Subscribe for More!

| [![Nikhil Vaghela](https://img.shields.io/badge/YouTube-Nikhil%20Vaghela-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/@Nikhil-Vaghela0716) |
|:--:|
| **Don't forget to Like 👍, Share 📤, and Subscribe 🔔!** |
