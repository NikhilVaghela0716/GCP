#!/bin/bash

# ================= COLORS =================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# ================= WELCOME =================
echo -e "${TEAL_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo -e "${TEAL_TEXT}${BOLD_TEXT}     🚀 DOCKER + ARTIFACT REGISTRY LAB AUTOMATION 🚀          ${RESET_FORMAT}"
echo -e "${TEAL_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo -e "${CYAN_TEXT}Author:${RESET_FORMAT} ${WHITE_TEXT}Nikhil Vaghela${RESET_FORMAT}"
echo -e "${CYAN_TEXT}YouTube:${RESET_FORMAT} ${UNDERLINE_TEXT}${BLUE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo

# ================= INPUT =================
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT} " REGION
echo

# ================= STEPS =================
echo -e "${PURPLE_TEXT}${BOLD_TEXT}🔐 Step 1:${RESET_FORMAT} ${CYAN_TEXT}Authenticating with gcloud...${RESET_FORMAT}"
gcloud auth list
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}📁 Step 2:${RESET_FORMAT} ${CYAN_TEXT}Creating working directory...${RESET_FORMAT}"
mkdir test && cd test
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}🐳 Step 3:${RESET_FORMAT} ${CYAN_TEXT}Creating Dockerfile...${RESET_FORMAT}"
cat > Dockerfile <<EOF
FROM node:lts
WORKDIR /app
ADD . /app
EXPOSE 80
CMD ["node", "app.js"]
EOF
echo -e "${GREEN_TEXT}✔ Dockerfile created${RESET_FORMAT}"
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}📜 Step 4:${RESET_FORMAT} ${CYAN_TEXT}Creating app.js...${RESET_FORMAT}"
cat > app.js <<EOF
const http = require("http");
const hostname = "0.0.0.0";
const port = 80;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader("Content-Type", "text/plain");
  res.end("Welcome to Cloud\n");
});

server.listen(port, hostname);
EOF
echo -e "${GREEN_TEXT}✔ app.js created${RESET_FORMAT}"
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}🔨 Step 5:${RESET_FORMAT} ${CYAN_TEXT}Building Docker image...${RESET_FORMAT}"
docker build -t node-app:0.2 .
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}▶ Step 6:${RESET_FORMAT} ${CYAN_TEXT}Running Docker container...${RESET_FORMAT}"
docker run -p 8080:80 --name my-app-2 -d node-app:0.2
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}📦 Step 7:${RESET_FORMAT} ${CYAN_TEXT}Listing running containers...${RESET_FORMAT}"
docker ps
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}🗄 Step 8:${RESET_FORMAT} ${CYAN_TEXT}Creating Artifact Registry...${RESET_FORMAT}"
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository"
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}🔑 Step 9:${RESET_FORMAT} ${CYAN_TEXT}Configuring Docker authentication...${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet
echo

DEVSHELL_PROJECT_ID=$(gcloud config get-value project)

echo -e "${PURPLE_TEXT}${BOLD_TEXT}🏗 Step 10:${RESET_FORMAT} ${CYAN_TEXT}Building image for Artifact Registry...${RESET_FORMAT}"
docker build -t $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2 .
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}🚀 Step 11:${RESET_FORMAT} ${CYAN_TEXT}Pushing image to Artifact Registry...${RESET_FORMAT}"
docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}🧹 Step 12:${RESET_FORMAT} ${CYAN_TEXT}Cleaning Docker environment...${RESET_FORMAT}"
docker stop $(docker ps -q)
docker rm $(docker ps -aq)
docker rmi -f $(docker images -aq)
echo

echo -e "${PURPLE_TEXT}${BOLD_TEXT}▶ Step 13:${RESET_FORMAT} ${CYAN_TEXT}Running image from Artifact Registry...${RESET_FORMAT}"
docker run -p 4000:80 -d $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2
echo

# ================= FINAL =================
echo
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}      LAB COMPLETED SUCCESSFULLY - NIKHIL VAGHELA        ${RESET_FORMAT}"
echo -e "${GOLD_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo -e "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo -e "${PURPLE_TEXT}${BOLD_TEXT}Don't forget to Like, Share & Subscribe 🚀${RESET_FORMAT}"
