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


# Ask user for ZONE (with validation + color)
while true; do
  echo -ne "${BLUE_TEXT}${BOLD_TEXT}Enter your GCP Zone : ${RESET_FORMAT}"
  read ZONE

  if [[ -n "$ZONE" ]]; then
    echo -e "${BLUE_TEXT}  ✔ Zone accepted: ${RED_TEXT}${BOLD_TEXT}$ZONE${RESET_FORMAT}"
    echo ""
    break
  else
    echo -e "${RED_TEXT}  ✘ Zone cannot be empty. Please enter a valid zone.${RESET_FORMAT}"
  fi
done

echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Authenticating with Google Cloud...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud auth list

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID

echo -e "${BLUE_TEXT}  >> Setting compute zone to: ${RED_TEXT}${BOLD_TEXT}$ZONE${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

export REGION=${ZONE%-*}
echo -e "${BLUE_TEXT}  >> Setting compute region to: ${RED_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}"
gcloud config set compute/region $REGION

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Creating GKE Cluster: scaling-demo (3 nodes)...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud container clusters create scaling-demo --num-nodes=3 --enable-vertical-pod-autoscaling

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Deploying php-apache Workload...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
cat << EOF > php-apache.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  selector:
    matchLabels:
      run: php-apache
  replicas: 3
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: k8s.gcr.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    run: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache
EOF

kubectl apply -f php-apache.yaml

echo -e "${BLUE_TEXT}  >> Fetching Deployment Status...${RESET_FORMAT}"
kubectl get deployment

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Configuring Horizontal Pod Autoscaler (HPA)...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10

echo -e "${BLUE_TEXT}  >> HPA Status:${RESET_FORMAT}"
kubectl get hpa

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Verifying Vertical Pod Autoscaling (VPA) on Cluster...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud container clusters describe scaling-demo | grep ^verticalPodAutoscaling -A 1

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Deploying hello-server Application...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0

echo -e "${BLUE_TEXT}  >> hello-server Deployment Status:${RESET_FORMAT}"
kubectl get deployment hello-server

echo -e "${BLUE_TEXT}  >> Setting CPU Resource Requests for hello-server...${RESET_FORMAT}"
kubectl set resources deployment hello-server --requests=cpu=450m

echo -e "${BLUE_TEXT}  >> Pod Description (hello-server):${RESET_FORMAT}"
kubectl describe pod hello-server | sed -n "/Containers:$/,/Conditions:/p"

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Applying Vertical Pod Autoscaler (VPA) — Mode: Off...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
cat << EOF > hello-vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: hello-server-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       hello-server
  updatePolicy:
    updateMode: "Off"
EOF

kubectl apply -f hello-vpa.yaml

echo -e "${BLUE_TEXT}  >> VPA Description:${RESET_FORMAT}"
kubectl describe vpa hello-server-vpa

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Switching VPA Mode to Auto...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
sed -i 's/Off/Auto/g' hello-vpa.yaml
kubectl apply -f hello-vpa.yaml

echo -e "${BLUE_TEXT}  >> Scaling hello-server to 2 Replicas...${RESET_FORMAT}"
kubectl scale deployment hello-server --replicas=2

echo -e "${BLUE_TEXT}  >> Pod Listing:${RESET_FORMAT}"
kubectl get pods

echo -e "${BLUE_TEXT}  >> HPA Overview:${RESET_FORMAT}"
kubectl get hpa

echo -e "${BLUE_TEXT}  >> Updated Pod Description (hello-server):${RESET_FORMAT}"
kubectl describe pod hello-server | sed -n "/Containers:$/,/Conditions:/p"

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Enabling Cluster Autoscaler (min: 1, max: 5 nodes)...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud beta container clusters update scaling-demo --enable-autoscaling --min-nodes 1 --max-nodes 5

echo -e "${BLUE_TEXT}  >> Applying Autoscaling Profile: optimize-utilization...${RESET_FORMAT}"
gcloud beta container clusters update scaling-demo \
--autoscaling-profile optimize-utilization

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Creating Pod Disruption Budgets (PDBs)...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
kubectl create poddisruptionbudget kube-dns-pdb --namespace=kube-system --selector k8s-app=kube-dns --max-unavailable 1
kubectl create poddisruptionbudget prometheus-pdb --namespace=kube-system --selector k8s-app=prometheus-to-sd --max-unavailable 1
kubectl create poddisruptionbudget kube-proxy-pdb --namespace=kube-system --selector component=kube-proxy --max-unavailable 1
kubectl create poddisruptionbudget metrics-agent-pdb --namespace=kube-system --selector k8s-app=gke-metrics-agent --max-unavailable 1
kubectl create poddisruptionbudget metrics-server-pdb --namespace=kube-system --selector k8s-app=metrics-server --max-unavailable 1
kubectl create poddisruptionbudget fluentd-pdb --namespace=kube-system --selector k8s-app=fluentd-gke --max-unavailable 1
kubectl create poddisruptionbudget backend-pdb --namespace=kube-system --selector k8s-app=glbc --max-unavailable 1
kubectl create poddisruptionbudget kube-dns-autoscaler-pdb --namespace=kube-system --selector k8s-app=kube-dns-autoscaler --max-unavailable 1
kubectl create poddisruptionbudget stackdriver-pdb --namespace=kube-system --selector app=stackdriver-metadata-agent --max-unavailable 1
kubectl create poddisruptionbudget event-pdb --namespace=kube-system --selector k8s-app=event-exporter --max-unavailable 1

echo -e "${BLUE_TEXT}  >> Node Listing:${RESET_FORMAT}"
kubectl get nodes

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Enabling Node Auto-Provisioning...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
gcloud container clusters update scaling-demo \
    --enable-autoprovisioning \
    --min-cpu 1 \
    --min-memory 2 \
    --max-cpu 45 \
    --max-memory 160

echo ""
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
echo -e "${BLUE_TEXT}  >> Deploying Overprovisioning Pause Pod...${RESET_FORMAT}"
echo -e "${BLUE_TEXT}------------------------------------------------------------------${RESET_FORMAT}"
cat << EOF > pause-pod.yaml
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: overprovisioning
value: -1
globalDefault: false
description: "Priority class used by overprovisioning."
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: overprovisioning
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      run: overprovisioning
  template:
    metadata:
      labels:
        run: overprovisioning
    spec:
      priorityClassName: overprovisioning
      containers:
      - name: reserve-resources
        image: k8s.gcr.io/pause
        resources:
          requests:
            cpu: 1
            memory: 4Gi
EOF

kubectl apply -f pause-pod.yaml

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
