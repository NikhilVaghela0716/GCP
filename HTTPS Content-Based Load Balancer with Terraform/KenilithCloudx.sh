#!/bin/bash

# =========================
# COLOR DEFINITIONS (ONLY RED & BLUE)
# =========================
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# =========================
# WELCOME MESSAGE
# =========================
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo "${BLUE}${BOLD}              🚀 GOOGLE CLOUD LAB | Kenilith Cloudx 🚀           ${RESET}"
echo "${BLUE}${BOLD}==================================================================${RESET}"
echo

# =========================
# REGION INPUT
# =========================
echo "${BLUE}${BOLD}Region Configuration${RESET}"
echo "${BLUE}Please enter the regions for your backend groups:${RESET}"

read -p "Enter Group 1 Region : " group1_region
read -p "Enter Group 2 Region : " group2_region
read -p "Enter Group 3 Region : " group3_region
echo

# =========================
# CLONE TERRAFORM MODULE
# =========================
echo "${BLUE}${BOLD}Cloning Terraform HTTP Load Balancer module...${RESET}"
git clone https://github.com/terraform-google-modules/terraform-google-lb-http.git

cd ~/terraform-google-lb-http/examples/multi-backend-multi-mig-bucket-https-lb || {
    echo "${RED}${BOLD}Failed to change directory${RESET}"
    exit 1
}

# =========================
# DOWNLOAD CONFIG
# =========================
echo "${BLUE}${BOLD}Downloading Load Balancer configuration${RESET}"
rm -rf main.tf
wget -q https://raw.githubusercontent.com/quiccklabs/Labs_solutions/master/HTTPS%20Content-Based%20Load%20Balancer%20with%20Terraform/main.tf

# =========================
# VARIABLES FILE
# =========================
echo "${BLUE}${BOLD}Generating Terraform File${RESET}"

cat > variables.tf <<EOF
variable "group1_region" {
  default = "$group1_region"
}

variable "group2_region" {
  default = "$group2_region"
}

variable "group3_region" {
  default = "$group3_region"
}

variable "network_name" {
  default = "ml-bk-ml-mig-bkt-s-lb"
}

variable "project" {
  type = string
}
EOF

# =========================
# TERRAFORM EXECUTION
# =========================
echo "${BLUE}${BOLD}Initializing Terraform${RESET}"
terraform init

echo "${BLUE}${BOLD}Planning infrastructure${RESET}"
echo $DEVSHELL_PROJECT_ID | terraform plan

echo "${BLUE}${BOLD}Applying configuration${RESET}"
echo $DEVSHELL_PROJECT_ID | terraform apply -auto-approve

# =========================
# LOAD BALANCER IP
# =========================
EXTERNAL_IP=$(terraform output | grep load-balancer-ip | cut -d = -f2 | xargs echo -n)

echo
echo "${RED}${BOLD}Load Balancer IP: $EXTERNAL_IP${RESET}"

# =========================
# COMPLETION FOOTER
# =========================
echo
echo "${RED}${BOLD}==============================================================${RESET}"
echo "${RED}${BOLD}                ✅ LAB COMPLETED SUCCESSFULLY!                ${RESET}"
echo "${RED}${BOLD}==============================================================${RESET}"
echo
echo "${BLUE}${BOLD}🙏 Thanks for learning with Kenilith Cloudx${RESET}"
echo "${RED}${BOLD}📢 Subscribe for more Google Cloud Labs:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@KenilithCloudx${RESET}"
echo
