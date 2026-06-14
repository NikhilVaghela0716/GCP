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

BG_BLUE='\033[44m'
BG_GREEN='\033[42m'
BG_RED='\033[41m'

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
clear

# ══════════════════════════════════════════
#  WELCOME BANNER
# ══════════════════════════════════════════
echo
echo -e "${BOLD}${CYAN}  ╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}  ║                                                   ║${RESET}"
echo -e "${BOLD}${CYAN}  ║   ${WHITE}🚀  GOOGLE CLOUD  │  KenilithCloudX          ${CYAN}║${RESET}"
echo -e "${BOLD}${CYAN}  ║   ${DIM}${WHITE}Network Load Balancer Lab Setup               ${CYAN}${BOLD}║${RESET}"
echo -e "${BOLD}${CYAN}  ║                                                   ║${RESET}"
echo -e "${BOLD}${CYAN}  ╚═══════════════════════════════════════════════════╝${RESET}"
echo


# ══════════════════════════════════════════
#  ZONE CONFIGURATION
# ══════════════════════════════════════════
section "ZONE CONFIGURATION"

echo -e "  ${YELLOW}  ?  ${YELLOW}Enter the compute zone${RESET} ${DIM}(e.g. us-central1-a)${RESET}"
echo -ne "  ${BOLD}${WHITE}      → ${RESET}"
read ZONE

if [[ -z "$ZONE" ]]; then
    error_msg "Zone cannot be empty. Exiting."
    exit 1
fi

REGION=${ZONE%-*}

gcloud config set compute/region "$REGION" --quiet
gcloud config set compute/zone   "$ZONE"   --quiet

echo
kv "Zone"   "$ZONE"
kv "Region" "$REGION"
success "Zone configuration applied."


# ══════════════════════════════════════════
#  WEB SERVER SETUP
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
      --metadata=startup-script="#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo '<h3>Web Server: $server_name</h3>' > /var/www/html/index.html" \
      --quiet

    success "Instance ${CYAN}${server_name}${WHITE} created."
}

create_web_server www1
create_web_server www2
create_web_server www3

echo
success "All 3 web server instances launched."


# ══════════════════════════════════════════
#  FIREWALL SETUP
# ══════════════════════════════════════════
section "FIREWALL SETUP"

step "Creating firewall rule for HTTP traffic on port 80 ..."

gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag \
    --allow tcp:80 \
    --quiet

success "Firewall rule ${CYAN}www-firewall-network-lb${WHITE} created."


# ══════════════════════════════════════════
#  VERIFY INSTANCES
# ══════════════════════════════════════════
section "INSTANCE VERIFICATION"

step "Fetching instance list ..."
echo
gcloud compute instances list
echo

warn "Waiting 30 seconds for startup scripts to complete ..."
sleep 30
success "Startup wait complete."


# ══════════════════════════════════════════
#  NETWORK LOAD BALANCER
# ══════════════════════════════════════════
section "NETWORK LOAD BALANCER"

step "Reserving static external IP address ..."
gcloud compute addresses create network-lb-ip-1 \
    --region="$REGION" --quiet
success "IP address reserved."

step "Creating HTTP health check ..."
gcloud compute http-health-checks create basic-check --quiet
success "Health check created."

step "Creating target pool ..."
gcloud compute target-pools create www-pool \
    --region="$REGION" \
    --http-health-check basic-check --quiet
success "Target pool created."

step "Adding instances to target pool ..."
gcloud compute target-pools add-instances www-pool \
    --instances www1,www2,www3 --quiet
success "Instances added to pool."

step "Creating forwarding rule ..."
gcloud compute forwarding-rules create www-rule \
    --region="$REGION" \
    --ports=80 \
    --address=network-lb-ip-1 \
    --target-pool=www-pool --quiet
success "Forwarding rule created."

echo
warn "Waiting 30 seconds for health checks to stabilize ..."
sleep 30

IPADDRESS=$(gcloud compute forwarding-rules describe www-rule \
    --region="$REGION" \
    --format="get(IPAddress)")

echo
print_dline
echo -e "  ${BOLD}${GREEN}  ✔  Load Balancer ready!${RESET}"
kv "Public IP" "$IPADDRESS"
print_dline


# ══════════════════════════════════════════
#  LOAD BALANCER TEST
# ══════════════════════════════════════════
section "TESTING LOAD BALANCER"

step "Sending 10 test requests to ${CYAN}http://${IPADDRESS}${WHITE} ..."
echo

for i in {1..10}; do
    RESPONSE=$(curl -s "http://$IPADDRESS")
    echo -e "  ${DIM}[${i}/10]${RESET}  ${GREEN}${RESPONSE}${RESET}"
done


# ══════════════════════════════════════════
#  COMPLETION BANNER
# ══════════════════════════════════════════
echo
echo -e "${BOLD}${GREEN}  ╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}  ║                                                   ║${RESET}"
echo -e "${BOLD}${GREEN}  ║   ${WHITE}✅  LAB COMPLETE — All steps finished!         ${GREEN}║${RESET}"
echo -e "${BOLD}${GREEN}  ║                                                   ║${RESET}"
echo -e "${BOLD}${GREEN}  ╚═══════════════════════════════════════════════════╝${RESET}"
echo
echo -e "  ${BOLD}${WHITE}Thank you for learning with ${CYAN}KenilithCloudX${WHITE}! 🙏${RESET}"
echo -e "  ${DIM}Subscribe for more hands-on Google Cloud labs:${RESET}"
echo -e "  ${BOLD}${CYAN}  https://www.youtube.com/@KenilithCloudx${RESET}"
echo
