#!/bin/bash

# Define color variables
RED_TEXT=$'\033[0;91m'
BLUE_TEXT=$'\033[0;94m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

# =========================
# WELCOME MESSAGE
# =========================
echo -e "${BLUE_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${BLUE_TEXT}         🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀              ${RESET_FORMAT}"
echo -e "${BLUE_TEXT}==================================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}  >> Initializing Lab Environment... Please Wait <<${RESET_FORMAT}"
echo ""

# ========================= FETCH ZONE & REGION =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Fetching project zone and region...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"

ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
PROJECT_ID=$(gcloud config get-value project)

echo -e "${BLUE_TEXT}  ✔ Zone    : ${RED_TEXT}${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  ✔ Region  : ${RED_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  ✔ Project : ${RED_TEXT}${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo ""

# ========================= AUTH & CONFIG =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Validating Authentication and Setting Configuration...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud auth list
gcloud config set project $DEVSHELL_PROJECT_ID
gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"
echo ""

# ========================= CREATE GKE CLUSTER =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Creating GKE Cluster: test-cluster (3 nodes)...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud container clusters create test-cluster --num-nodes=3 --enable-ip-alias
echo ""

# ========================= FRONTEND POD =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Deploying Frontend Pod...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
cat << EOF > gb_frontend_pod.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: gb-frontend
  name: gb-frontend
spec:
    containers:
    - name: gb-frontend
      image: gcr.io/google-samples/gb-frontend-amd64:v5
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
      ports:
      - containerPort: 80
EOF

kubectl apply -f gb_frontend_pod.yaml
echo ""

# ========================= CLUSTER IP SERVICE =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Creating ClusterIP Service...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
cat << EOF > gb_frontend_cluster_ip.yaml
apiVersion: v1
kind: Service
metadata:
  name: gb-frontend-svc
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
spec:
  type: ClusterIP
  selector:
    app: gb-frontend
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
EOF

kubectl apply -f gb_frontend_cluster_ip.yaml
echo ""

# ========================= INGRESS =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Creating Ingress Resource...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
cat << EOF > gb_frontend_ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gb-frontend-ingress
spec:
  defaultBackend:
    service:
      name: gb-frontend-svc
      port:
        number: 80
EOF

kubectl apply -f gb_frontend_ingress.yaml
echo ""

# ========================= WAIT =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}  >> Waiting for Backend Services to Initialize (10 min)...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
sleep 600

# ========================= BACKEND HEALTH =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Checking Backend Service Health...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
BACKEND_SERVICE=$(gcloud compute backend-services list | grep NAME | cut -d ' ' -f2)
gcloud compute backend-services get-health $BACKEND_SERVICE --global

BACKEND_SERVICE=$(gcloud compute backend-services list | grep NAME | cut -d ' ' -f2)
gcloud compute backend-services get-health $BACKEND_SERVICE --global

echo -e "${BLUE_TEXT}  >> Fetching Ingress Status...${RESET_FORMAT}"
kubectl get ingress gb-frontend-ingress
echo ""

# ========================= PART 2 =========================
echo -e "${BLUE_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}  >> Proceeding to Part 2...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}==================================================================${RESET_FORMAT}"

while true; do
    echo -ne "${BLUE_TEXT}${BOLD_TEXT}Do you want to proceed? (Y/n): ${RESET_FORMAT}"
    read confirm
    case "$confirm" in
        [Yy])
            echo -e "${BLUE_TEXT}  ✔ Confirmed! Continuing execution...${RESET_FORMAT}"
            break
            ;;
        [Nn]|"")
            echo -e "${RED_TEXT}  ✘ Operation canceled by user.${RESET_FORMAT}"
            break
            ;;
        *)
            echo -e "${RED_TEXT}  ✘ Invalid input. Please enter Y or N.${RESET_FORMAT}"
            ;;
    esac
done
echo ""

# ========================= LOCUST SETUP =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Downloading Locust Files from GCS...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gsutil -m cp -r gs://spls/gsp769/locust-image .

echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Building Locust Container Image...${RESET_FORMAT}"
gcloud builds submit \
    --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/locust-tasks:latest locust-image

echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Deploying Locust to Kubernetes...${RESET_FORMAT}"
gsutil cp gs://spls/gsp769/locust_deploy_v2.yaml .
sed 's/${GOOGLE_CLOUD_PROJECT}/'$GOOGLE_CLOUD_PROJECT'/g' locust_deploy_v2.yaml | kubectl apply -f -

echo -e "${BLUE_TEXT}  >> Locust Service Status:${RESET_FORMAT}"
kubectl get service locust-main
echo ""

# ========================= LIVENESS PROBE =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Deploying Liveness Probe Demo...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
cat > liveness-demo.yaml <<EOF_END
apiVersion: v1
kind: Pod
metadata:
  labels:
    demo: liveness-probe
  name: liveness-demo-pod
spec:
  containers:
  - name: liveness-demo-pod
    image: centos
    args:
    - /bin/sh
    - -c
    - touch /tmp/alive; sleep infinity
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/alive
      initialDelaySeconds: 5
      periodSeconds: 10
EOF_END

kubectl apply -f liveness-demo.yaml
echo -e "${BLUE_TEXT}  >> Describing Liveness Demo Pod...${RESET_FORMAT}"
kubectl describe pod liveness-demo-pod
echo -e "${RED_TEXT}${BOLD_TEXT}  >> Removing liveness file to trigger probe failure...${RESET_FORMAT}"
kubectl exec liveness-demo-pod -- rm /tmp/alive
echo -e "${BLUE_TEXT}  >> Pod Status After Probe Failure:${RESET_FORMAT}"
kubectl describe pod liveness-demo-pod
echo ""

# ========================= READINESS PROBE =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Deploying Readiness Probe Demo...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
cat << EOF > readiness-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    demo: readiness-probe
  name: readiness-demo-pod
spec:
  containers:
  - name: readiness-demo-pod
    image: nginx
    ports:
    - containerPort: 80
    readinessProbe:
      exec:
        command:
        - cat
        - /tmp/healthz
      initialDelaySeconds: 5
      periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: readiness-demo-svc
  labels:
    demo: readiness-probe
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  selector:
    demo: readiness-probe
EOF

kubectl apply -f readiness-demo.yaml
echo -e "${BLUE_TEXT}  >> Readiness Demo Service:${RESET_FORMAT}"
kubectl get service readiness-demo-svc
echo -e "${BLUE_TEXT}  >> Readiness Demo Pod Description:${RESET_FORMAT}"
kubectl describe pod readiness-demo-pod

echo -e "${RED_TEXT}${BOLD_TEXT}  >> Waiting 45 seconds before marking pod healthy...${RESET_FORMAT}"
sleep 45

echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Touching /tmp/healthz to mark pod as ready...${RESET_FORMAT}"
kubectl exec readiness-demo-pod -- touch /tmp/healthz
echo -e "${BLUE_TEXT}  >> Pod Conditions After Readiness Signal:${RESET_FORMAT}"
kubectl describe pod readiness-demo-pod | grep ^Conditions -A 5
echo ""

# ========================= DEPLOYMENT UPDATE =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Upgrading Frontend Pod to Deployment (5 replicas)...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
kubectl delete pod gb-frontend

cat << EOF > gb_frontend_deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gb-frontend
  labels:
    run: gb-frontend
spec:
  replicas: 5
  selector:
    matchLabels:
      run: gb-frontend
  template:
    metadata:
      labels:
        run: gb-frontend
    spec:
      containers:
        - name: gb-frontend
          image: gcr.io/google-samples/gb-frontend-amd64:v5
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
          ports:
            - containerPort: 80
              protocol: TCP
EOF

kubectl apply -f gb_frontend_deployment.yaml
echo ""

# ========================= LOCUST UI =========================
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}  >> Rebuilding Locust Image and Fetching UI URL...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud builds submit \
    --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/locust-tasks:latest locust-image

export LOCUST_IP=$(kubectl get svc locust-main -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl http://$LOCUST_IP:8089
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}  🌐 Locust UI is Live at: ${BLUE_TEXT}http://$LOCUST_IP:8089${RESET_FORMAT}"
echo ""

# =========================
# COMPLETION FOOTER
# =========================
echo -e "${RED_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${RED_TEXT}            ✅  LAB COMPLETED SUCCESSFULLY !  ✅               ${RESET_FORMAT}"
echo -e "${RED_TEXT}==================================================================${RESET_FORMAT}"
echo ""
echo -e "${BLUE_TEXT}  Thank you for learning with Kenilith Cloudx!${RESET_FORMAT}"
echo -e "${RED_TEXT}  Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  👉  https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo ""
