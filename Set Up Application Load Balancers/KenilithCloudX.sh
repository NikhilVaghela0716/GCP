#!/bin/bash

# ══════════════════════════════════════════
#  COLOR & STYLE DEFINITIONS
# ══════════════════════════════════════════
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

BLACK='\033[0;30m'
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
MAGENTA='\033[0;95m'
CYAN='\033[0;96m'
WHITE='\033[0;97m'

# ── Utility Helpers ──────────────────────
print_line()    { echo -e "${DIM}${CYAN}  ─────────────────────────────────────────────────${RESET}"; }
print_dline()   { echo -e "${CYAN}  ═════════════════════════════════════════════════${RESET}"; }
section()       { echo; echo -e "${BOLD}${BLUE}  ┌─ ${WHITE}$1${RESET}"; print_line; }
info()          { echo -e "  ${CYAN}  ℹ  ${WHITE}$1${RESET}"; }
success()       { echo -e "  ${GREEN}  ✔  ${WHITE}$1${RESET}"; }
warn()          { echo -e "  ${YELLOW}  ⚠  ${YELLOW}$1${RESET}"; }
error_msg()     { echo -e "  ${RED}  ✖  ${RED}$1${RESET}"; }
step()          { echo -e "  ${MAGENTA}  ➤  ${WHITE}$1${RESET}"; }
kv()            { echo -e "  ${DIM}     ${CYAN}$1:${RESET}  ${BOLD}${WHITE}$2${RESET}"; }

clear

# ══════════════════════════════════════════
#  WELCOME BANNER
# ══════════════════════════════════════════
echo
echo -e "${BOLD}${CYAN}  ╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}  ║                                                   ║${RESET}"
echo -e "${BOLD}${CYAN}  ║   ${WHITE}💻  TECH & CODE  │  HTTP Load Balancer Lab     ${CYAN}║${RESET}"
echo -e "${BOLD}${CYAN}  ║   ${DIM}${WHITE}Initiating execution...                       ${CYAN}${BOLD}║${RESET}"
echo -e "${BOLD}${CYAN}  ║                                                   ║${RESET}"
echo -e "${BOLD}${CYAN}  ╚═══════════════════════════════════════════════════╝${RESET}"
echo


# ══════════════════════════════════════════
#  AUTH & ZONE CONFIGURATION
# ══════════════════════════════════════════
section "AUTHENTICATION & ZONE CONFIGURATION"

step "Listing active gcloud accounts ..."
echo
gcloud auth list
echo

echo -e "  ${YELLOW}  ?  ${YELLOW}Enter the compute zone${RESET} ${DIM}(e.g. us-central1-a)${RESET}"
echo -ne "  ${BOLD}${WHITE}      → ${RESET}"
read ZONE

if [[ -z "$ZONE" ]]; then
    error_msg "Zone cannot be empty. Exiting."
    exit 1
fi

export REGION=${ZONE%-*}

gcloud config set compute/zone "$ZONE" --quiet
gcloud config set compute/region "$REGION" --quiet

echo
kv "Zone"   "$ZONE"
kv "Region" "$REGION"
success "Zone configuration applied."


# ══════════════════════════════════════════
#  WEB SERVER SETUP (network LB backends)
# ══════════════════════════════════════════
section "WEB SERVER SETUP"

create_web_server() {
    local server_name=$1
    step "Creating instance: ${CYAN}${server_name}${WHITE} ..."

    gcloud compute instances create "$server_name" \
      --zone="$ZONE" \
      --tags=network-lb-tag \
      --machine-type=e2-small \
      --image-family=debian-11 \
      --image-project=debian-cloud \
      --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "
<h3>Web Server: '"$server_name"'</h3>" | tee /var/www/html/index.html' \
      --quiet

    success "Instance ${CYAN}${server_name}${WHITE} created."
}

create_web_server www1
create_web_server www2
create_web_server www3

echo
success "All 3 web server instances launched."


# ══════════════════════════════════════════
#  FIREWALL — network LB
# ══════════════════════════════════════════
section "FIREWALL SETUP (Network LB)"

step "Creating firewall rule for HTTP traffic on port 80 ..."

gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80 --quiet

success "Firewall rule ${CYAN}www-firewall-network-lb${WHITE} created."

echo
step "Fetching instance list ..."
echo
gcloud compute instances list
echo


# ══════════════════════════════════════════
#  INSTANCE TEMPLATE & MANAGED GROUP
# ══════════════════════════════════════════
section "INSTANCE TEMPLATE & MANAGED GROUP"

step "Creating instance template ${CYAN}lb-backend-template${WHITE} ..."

gcloud compute instance-templates create lb-backend-template \
   --region="$REGION" \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-11 \
   --image-project=debian-cloud \
   --metadata=startup-script='#!/bin/bash
     apt-get update
     apt-get install apache2 -y
     a2ensite default-ssl
     a2enmod ssl
     vm_hostname="$(curl -H "Metadata-Flavor:Google" \
     http://169.254.169.254/computeMetadata/v1/instance/name)"
     echo "Page served from: $vm_hostname" | \
     tee /var/www/html/index.html
     systemctl restart apache2' \
   --quiet

success "Instance template created."

step "Creating managed instance group ${CYAN}lb-backend-group${WHITE} ..."

gcloud compute instance-groups managed create lb-backend-group \
   --template=lb-backend-template --size=2 --zone="$ZONE" --quiet

success "Managed instance group created."

echo
warn "Waiting 60 seconds for managed instances to start ..."
sleep 60
success "Startup wait complete."


# ══════════════════════════════════════════
#  FIREWALL — health checks
# ══════════════════════════════════════════
section "FIREWALL SETUP (Health Checks)"

step "Creating firewall rule for health-check ranges ..."

gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80 --quiet

success "Firewall rule ${CYAN}fw-allow-health-check${WHITE} created."


# ══════════════════════════════════════════
#  GLOBAL IP ADDRESS
# ══════════════════════════════════════════
section "GLOBAL IP ADDRESS"

step "Reserving global static IP ${CYAN}lb-ipv4-1${WHITE} ..."

gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global --quiet

success "Global IP reserved."

LB_IP=$(gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global)

echo
kv "Reserved IP" "$LB_IP"


# ══════════════════════════════════════════
#  HTTP LOAD BALANCER
# ══════════════════════════════════════════
section "HTTP LOAD BALANCER SETUP"

step "Creating HTTP health check ..."
gcloud compute health-checks create http http-basic-check \
  --port 80 --quiet
success "Health check created."

step "Creating backend service ..."
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global --quiet
success "Backend service created."

step "Attaching managed instance group to backend service ..."
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone="$ZONE" \
  --global --quiet
success "Backend attached."

step "Creating URL map ..."
gcloud compute url-maps create web-map-http \
    --default-service web-backend-service --quiet
success "URL map created."

step "Creating target HTTP proxy ..."
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http --quiet
success "Target proxy created."

step "Creating global forwarding rule ..."
gcloud compute forwarding-rules create http-content-rule \
   --address=lb-ipv4-1 \
   --global \
   --target-http-proxy=http-lb-proxy \
   --ports=80 --quiet
success "Forwarding rule created."

echo
print_dline
echo -e "  ${BOLD}${GREEN}  ✔  HTTP Load Balancer ready!${RESET}"
kv "Public IP" "$LB_IP"
print_dline


# ══════════════════════════════════════════
#  COMPLETION BANNER
# ══════════════════════════════════════════
echo
echo -e "${BOLD}${GREEN}  ╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}  ║                                                          ║${RESET}"
echo -e "${BOLD}${GREEN}  ║   ${WHITE}✅  LAB COMPLETE — All steps finished!${GREEN}║${RESET}"
echo -e "${BOLD}${GREEN}  ║                                                          ║${RESET}"
echo -e "${BOLD}${GREEN}  ╚══════════════════════════════════════════════════════════╝${RESET}"
echo
echo -e "  ${BOLD}${RED}  https://www.youtube.com/@TechCode9${RESET}"
echo -e "  ${BOLD}${GREEN}  Don't forget to Like, Share and Subscribe for more videos!${RESET}"
echo
