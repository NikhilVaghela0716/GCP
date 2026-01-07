#!/bin/bash

# ===================== COLORS =====================
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
GOLD='\e[1;33m'
PURPLE='\e[1;35m'
NC='\e[0m'

BOLD='\e[1m'
UNDERLINE='\e[4m'

clear

# ===================== SPINNER =====================
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps a | awk '{print $1}' | grep -q "$pid"; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# ===================== UI FUNCTIONS =====================
print_header() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC} ${CYAN}$1${NC} ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# ===================== PROMO (SIMPLIFIED) =====================
echo -e "${CYAN}${BOLD}🚀 Kubernetes Lab Automation Script${NC}"
echo -e "${MAGENTA}Author:${NC} ${WHITE}Nikhil Vaghela${NC}"
echo -e "${CYAN}YouTube:${NC} ${WHITE}https://www.youtube.com/@Nikhil-Vaghela0716${NC}"
sleep 1

# ===================== FETCH CONFIG =====================
print_header "Fetching Google Cloud Configuration"
print_info "Detecting zone, region, and project..."

ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$ZONE" || -z "$REGION" || -z "$PROJECT_ID" ]]; then
    print_error "Failed to detect Google Cloud configuration."
    exit 1
fi

print_success "Zone: $ZONE"
print_success "Region: $REGION"
print_success "Project ID: $PROJECT_ID"

print_info "Setting compute zone..."
gcloud config set compute/zone "$ZONE" >/dev/null

# ===================== KUBERNETES SETUP =====================
print_header "Setting up Kubernetes Resources"
print_info "Copying Kubernetes configuration files..."
gcloud storage cp -r gs://spls/gsp053/kubernetes . & spinner $!
cd kubernetes || exit 1

# ===================== CREATE CLUSTER =====================
print_header "Creating GKE Cluster"
print_info "Creating Kubernetes cluster (3 nodes)..."
gcloud container clusters create bootcamp \
  --machine-type e2-small \
  --num-nodes 3 \
  --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw" & spinner $!
print_success "GKE cluster created successfully"

# ===================== TASK 2 =====================
print_header "TASK 2: Deploy Fortune App (Blue)"
kubectl create -f deployments/fortune-app-blue.yaml & spinner $!
kubectl create -f services/fortune-app.yaml & spinner $!

kubectl scale deployment fortune-app-blue --replicas=5 & spinner $!
print_success "Scaled to 5 replicas"

kubectl scale deployment fortune-app-blue --replicas=3 & spinner $!
print_success "Scaled to 3 replicas"

# ===================== TASK 3 =====================
print_header "TASK 3: Canary Deployment"
echo -ne "${CYAN}Continue with Task 3? [${GREEN}Y${NC}/${RED}N${NC}]: "
read -r CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { print_warning "Task aborted by user"; exit 0; }

kubectl set image deployment/fortune-app-blue \
fortune-app=$REGION-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/fortune-service:2.0.0 & spinner $!

kubectl set env deployment/fortune-app-blue APP_VERSION=2.0.0 & spinner $!
kubectl create -f deployments/fortune-app-canary.yaml & spinner $!

# ===================== TASK 5 =====================
print_header "TASK 5: Blue-Green Deployment"
kubectl apply -f services/fortune-app-blue-service.yaml & spinner $!
kubectl create -f deployments/fortune-app-green.yaml & spinner $!
kubectl apply -f services/fortune-app-green-service.yaml & spinner $!

# ===================== FINAL STATUS =====================
print_header "Cluster Status"
kubectl get deployments
kubectl get services
kubectl get pods

# ===================== FINAL BRANDING =====================
echo
echo -e "${GOLD}${BOLD}=======================================================${NC}"
echo -e "${GOLD}${BOLD}      LAB COMPLETED SUCCESSFULLY - NIKHIL VAGHELA        ${NC}"
echo -e "${GOLD}${BOLD}=======================================================${NC}"
echo
echo -e "${BLUE}${BOLD}${UNDERLINE}https://www.youtube.com/@Nikhil-Vaghela0716${NC}"
echo -e "${PURPLE}${BOLD}Don't forget to Like, Share & Subscribe 🚀${NC}"
