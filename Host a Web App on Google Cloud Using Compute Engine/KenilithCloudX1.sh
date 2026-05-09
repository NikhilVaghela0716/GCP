#!/bin/bash

# Color variables - Red and Blue only
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          🚀 WELCOME TO GOOGLE CLOUD — KenilithCloudX            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 1 ] ── Enabling Compute Engine API...${RESET_FORMAT}"
gcloud services enable compute.googleapis.com
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Compute Engine API enabled successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 2 ] ── Creating Cloud Storage bucket for the project...${RESET_FORMAT}"
gsutil mb gs://fancy-store-$DEVSHELL_PROJECT_ID
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Storage bucket 'fancy-store-$DEVSHELL_PROJECT_ID' created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 3 ] ── Cloning monolith-to-microservices repository from GitHub...${RESET_FORMAT}"
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Repository cloned successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 4 ] ── Running project setup script and installing Node.js LTS...${RESET_FORMAT}"
cd ~/monolith-to-microservices
./setup.sh
nvm install --lts
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Setup complete. Node.js LTS installed.${RESET_FORMAT}"
echo

cd monolith-to-microservices/

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 5 ] ── Generating VM startup script for backend instances...${RESET_FORMAT}"
cat > startup-script.sh <<EOF_START
#!/bin/bash
# Install logging monitor. The monitor will automatically pick up logs sent to syslog.
curl -s "https://storage.googleapis.com/signals-agents/logging/google-fluentd-install.sh" | bash
service google-fluentd restart &
# Install dependencies from apt
apt-get update
apt-get install -yq ca-certificates git build-essential supervisor psmisc
# Install nodejs
mkdir /opt/nodejs
curl https://nodejs.org/dist/v16.14.0/node-v16.14.0-linux-x64.tar.gz | tar xvzf - -C /opt/nodejs --strip-components=1
ln -s /opt/nodejs/bin/node /usr/bin/node
ln -s /opt/nodejs/bin/npm /usr/bin/npm
# Get the application source code from the Google Cloud Storage bucket.
mkdir /fancy-store
gsutil -m cp -r gs://fancy-store-$DEVSHELL_PROJECT_ID/monolith-to-microservices/microservices/* /fancy-store/
# Install app dependencies.
cd /fancy-store/
npm install
# Create a nodeapp user. The application will run as this user.
useradd -m -d /home/nodeapp nodeapp
chown -R nodeapp:nodeapp /opt/app
# Configure supervisor to run the node app.
cat >/etc/supervisor/conf.d/node-app.conf <<EOF_END
[program:nodeapp]
directory=/fancy-store
command=npm start
autostart=true
autorestart=true
user=nodeapp
environment=HOME="/home/nodeapp",USER="nodeapp",NODE_ENV="production"
stdout_logfile=syslog
stderr_logfile=syslog
EOF_END
supervisorctl reread
supervisorctl update
EOF_START
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Startup script generated successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 6 ] ── Uploading startup script to Cloud Storage bucket...${RESET_FORMAT}"
cd ~
gsutil cp ~/monolith-to-microservices/startup-script.sh gs://fancy-store-$DEVSHELL_PROJECT_ID
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Startup script uploaded to GCS.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 7 ] ── Uploading application source code to Cloud Storage...${RESET_FORMAT}"
cd ~
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Source code uploaded to GCS bucket.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 8 ] ── Creating backend Compute Engine instance...${RESET_FORMAT}"
gcloud compute instances create backend \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --tags=backend \
    --metadata=startup-script-url=https://storage.googleapis.com/fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Backend instance created and starting up.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 9 ] ── Listing all active compute instances...${RESET_FORMAT}"
gcloud compute instances list
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 10 ] ── Fetching external IP of backend instance...${RESET_FORMAT}"
export EXTERNAL_IP_BACKEND=$(gcloud compute instances describe backend --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Backend External IP : $EXTERNAL_IP_BACKEND${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 11 ] ── Configuring React app environment variables with backend IP...${RESET_FORMAT}"
cd monolith-to-microservices/react-app
cat > .env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_BACKEND:8081/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_BACKEND:8082/api/products
EOF
echo "${RED_TEXT}${BOLD_TEXT}  ➤ React .env file configured with backend endpoints.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 12 ] ── Installing dependencies and building React application...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
npm install && npm run-script build
echo "${RED_TEXT}${BOLD_TEXT}  ➤ React app build completed successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 13 ] ── Syncing updated build to Cloud Storage bucket...${RESET_FORMAT}"
cd ~
rm -rf monolith-to-microservices/*/node_modules
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Updated application synced to GCS.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 14 ] ── Creating frontend Compute Engine instance...${RESET_FORMAT}"
gcloud compute instances create frontend \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --tags=frontend \
    --metadata=startup-script-url=https://storage.googleapis.com/fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Frontend instance created and starting up.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 15 ] ── Creating firewall rules for frontend and backend traffic...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-fe \
    --allow tcp:8080 \
    --target-tags=frontend

gcloud compute firewall-rules create fw-be \
    --allow tcp:8081-8082 \
    --target-tags=backend
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Firewall rules 'fw-fe' and 'fw-be' created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 16 ] ── Listing all compute instances to verify setup...${RESET_FORMAT}"
gcloud compute instances list
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 17 ] ── Stopping frontend and backend instances for templating...${RESET_FORMAT}"
gcloud compute instances stop frontend --zone=$ZONE
gcloud compute instances stop backend --zone=$ZONE
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Both instances stopped successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 18 ] ── Creating instance templates from stopped instances...${RESET_FORMAT}"
gcloud compute instance-templates create fancy-fe \
    --source-instance-zone=$ZONE \
    --source-instance=frontend

gcloud compute instance-templates create fancy-be \
    --source-instance-zone=$ZONE \
    --source-instance=backend
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Instance templates 'fancy-fe' and 'fancy-be' created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 19 ] ── Listing all available instance templates...${RESET_FORMAT}"
gcloud compute instance-templates list
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 20 ] ── Deleting standalone backend instance (MIG will replace it)...${RESET_FORMAT}"
gcloud compute instances delete --quiet backend --zone=$ZONE
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Standalone backend instance deleted.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 21 ] ── Creating managed instance groups for frontend and backend...${RESET_FORMAT}"
gcloud compute instance-groups managed create fancy-fe-mig \
    --zone=$ZONE \
    --base-instance-name fancy-fe \
    --size 2 \
    --template fancy-fe

gcloud compute instance-groups managed create fancy-be-mig \
    --zone=$ZONE \
    --base-instance-name fancy-be \
    --size 2 \
    --template fancy-be
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Managed instance groups created with 2 replicas each.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 22 ] ── Configuring named ports for frontend and backend MIGs...${RESET_FORMAT}"
gcloud compute instance-groups set-named-ports fancy-fe-mig \
    --zone=$ZONE \
    --named-ports frontend:8080

gcloud compute instance-groups set-named-ports fancy-be-mig \
    --zone=$ZONE \
    --named-ports orders:8081,products:8082
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Named ports configured for load balancer routing.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 23 ] ── Setting up health checks for frontend and backend services...${RESET_FORMAT}"
gcloud compute health-checks create http fancy-fe-hc \
    --port 8080 \
    --check-interval 30s \
    --healthy-threshold 1 \
    --timeout 10s \
    --unhealthy-threshold 3

gcloud compute health-checks create http fancy-be-hc \
    --port 8081 \
    --request-path=/api/orders \
    --check-interval 30s \
    --healthy-threshold 1 \
    --timeout 10s \
    --unhealthy-threshold 3
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Health checks 'fancy-fe-hc' and 'fancy-be-hc' created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 24 ] ── Creating firewall rule to allow health check probes...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-health-check \
    --allow tcp:8080-8081 \
    --source-ranges 130.211.0.0/22,35.191.0.0/16 \
    --network default
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Health check firewall rule applied.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 25 ] ── Attaching health checks to managed instance groups...${RESET_FORMAT}"
gcloud compute instance-groups managed update fancy-fe-mig \
    --zone=$ZONE \
    --health-check fancy-fe-hc \
    --initial-delay 300

gcloud compute instance-groups managed update fancy-be-mig \
    --zone=$ZONE \
    --health-check fancy-be-hc \
    --initial-delay 300
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Health checks linked to both MIGs with 300s initial delay.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 26 ] ── Creating HTTP health checks for load balancer backend services...${RESET_FORMAT}"
gcloud compute http-health-checks create fancy-fe-frontend-hc \
  --request-path / \
  --port 8080

gcloud compute http-health-checks create fancy-be-orders-hc \
  --request-path /api/orders \
  --port 8081

gcloud compute http-health-checks create fancy-be-products-hc \
  --request-path /api/products \
  --port 8082
echo "${RED_TEXT}${BOLD_TEXT}  ➤ HTTP health checks created for frontend, orders, and products.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 27 ] ── Creating global backend services for load balancer...${RESET_FORMAT}"
gcloud compute backend-services create fancy-fe-frontend \
  --http-health-checks fancy-fe-frontend-hc \
  --port-name frontend \
  --global

gcloud compute backend-services create fancy-be-orders \
  --http-health-checks fancy-be-orders-hc \
  --port-name orders \
  --global

gcloud compute backend-services create fancy-be-products \
  --http-health-checks fancy-be-products-hc \
  --port-name products \
  --global
echo "${RED_TEXT}${BOLD_TEXT}  ➤ Backend services for frontend, orders, and products created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 28 ] ── Adding MIG backends to each backend service...${RESET_FORMAT}"
gcloud compute backend-services add-backend fancy-fe-frontend \
  --instance-group-zone=$ZONE \
  --instance-group fancy-fe-mig \
  --global

gcloud compute backend-services add-backend fancy-be-orders \
  --instance-group-zone=$ZONE \
  --instance-group fancy-be-mig \
  --global

gcloud compute backend-services add-backend fancy-be-products \
  --instance-group-zone=$ZONE \
  --instance-group fancy-be-mig \
  --global
echo "${RED_TEXT}${BOLD_TEXT}  ➤ MIG backends registered to all backend services.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 29 ] ── Creating URL map and configuring path-based routing rules...${RESET_FORMAT}"
gcloud compute url-maps create fancy-map \
  --default-service fancy-fe-frontend

gcloud compute url-maps add-path-matcher fancy-map \
   --default-service fancy-fe-frontend \
   --path-matcher-name orders \
   --path-rules "/api/orders=fancy-be-orders,/api/products=fancy-be-products"
echo "${RED_TEXT}${BOLD_TEXT}  ➤ URL map 'fancy-map' created with API path routing configured.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}[ STEP 30 ] ── Creating HTTP proxy and forwarding rule on port 80...${RESET_FORMAT}"
gcloud compute target-http-proxies create fancy-proxy \
  --url-map fancy-map

gcloud compute forwarding-rules create fancy-http-rule \
  --global \
  --target-http-proxy fancy-proxy \
  --ports 80
echo "${RED_TEXT}${BOLD_TEXT}  ➤ HTTP proxy and global forwarding rule created on port 80.${RESET_FORMAT}"
echo

# =========================
# FINAL MESSAGE
# =========================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}     ✅  ALL STEPS DONE — CHECK YOUR TASKS UP TO TASK 5 !        ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}  🙏 Thank you for practicing with KenilithCloudX${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}  📢 Subscribe for more hands-on Google Cloud content:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}  ${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
