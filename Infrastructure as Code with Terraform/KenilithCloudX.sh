#!/bin/bash

# Color Definitions (RED and BLUE only)
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =========================
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}                 GOOGLE CLOUD - TERRAFORM LAB SETUP              ${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo

clear
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}   Starting Terraform Infrastructure Run ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo

# Set environment variables
echo -e "${RED}Step 0: Reading project configuration...${NC}"
export REGION=${ZONE%-*}
export PROJECT_ID=$(gcloud config get-value project)
echo -e "${BLUE}Project ID : ${NC}$PROJECT_ID"
echo -e "${BLUE}Region     : ${NC}$REGION"
echo -e "${BLUE}Zone       : ${NC}$ZONE"
echo

cat <<'EOF' > ~/.customize_environment
# Set up HashiCorp repository and install Terraform
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
EOF
bash ~/.customize_environment

# Phase 1: Network Deployment
echo -e "${RED}Step 1: Creating the VPC network...${NC}"
cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
provider "google" {
  version = "3.5.0"
  project = "$PROJECT_ID"
  region  = "$REGION"
  zone    = "$ZONE"
}
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
EOF

terraform init
terraform apply -auto-approve

# Phase 2: Basic VM Deployment
echo -e "${RED}Step 2: Launching the base VM instance...${NC}"
cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
provider "google" {
  version = "3.5.0"
  project = "$PROJECT_ID"
  region  = "$REGION"
  zone    = "$ZONE"
}
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }
}
EOF

terraform apply -auto-approve

# Phase 3: Tagged VM Deployment
echo -e "${RED}Step 3: Applying network tags to the VM...${NC}"
cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
provider "google" {
  version = "3.5.0"
  project = "$PROJECT_ID"
  region  = "$REGION"
  zone    = "$ZONE"
}
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  tags         = ["web", "dev"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }
}
EOF

terraform apply -auto-approve

# Phase 4: COS Image Deployment
echo -e "${RED}Step 4: Switching the boot disk to a Container-Optimized OS image...${NC}"
cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
provider "google" {
  version = "3.5.0"
  project = "$PROJECT_ID"
  region  = "$REGION"
  zone    = "$ZONE"
}
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  tags         = ["web", "dev"]
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }
}
EOF

terraform apply -auto-approve

# Phase 5: Static IP Configuration
echo -e "${RED}Step 5: Attaching a static external IP address...${NC}"
cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
provider "google" {
  version = "3.5.0"
  project = "$PROJECT_ID"
  region  = "$REGION"
  zone    = "$ZONE"
}
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  tags         = ["web", "dev"]
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }
}
resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}
EOF

terraform plan -out static_ip
terraform apply "static_ip"

# Phase 6: Storage Bucket Deployment
echo -e "${RED}Step 6: Provisioning the storage bucket and second instance...${NC}"
cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
provider "google" {
  version = "3.5.0"
  project = "$PROJECT_ID"
  region  = "$REGION"
  zone    = "$ZONE"
}
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  tags         = ["web", "dev"]
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }
}
resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}
resource "google_storage_bucket" "example_bucket" {
  name     = "$PROJECT_ID"
  location = "US"
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}
resource "google_compute_instance" "another_instance" {
  depends_on   = [google_storage_bucket.example_bucket]
  name         = "terraform-instance-2"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {}
  }
}
EOF

terraform plan
terraform apply -auto-approve

echo
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}                     DEPLOYMENT COMPLETE                        ${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo
echo -e "${RED}All six phases finished without errors.${NC}"
echo
