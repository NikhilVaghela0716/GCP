#!/bin/bash

# ====================================================
# COLOR DEFINITIONS
# ====================================================
BLUE_TEXT=$(tput setaf 4)
RED_TEXT=$(tput setaf 1)
BOLD_TEXT=$(tput bold)
UNDERLINE_TEXT=$(tput smul)
RESET_FORMAT=$(tput sgr0)

clear

# ====================================================
# WELCOME MESSAGE
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}      INTERNAL LOAD BALANCER LAB | NIKHIL VAGHELA                 ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ====================================================
# STEP 1: CONFIGURATION
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 1: Configuration and Environment Setup${RESET_FORMAT}"

# User Input for ILB IP
read -p "${RED_TEXT}${BOLD_TEXT}Enter STATIC_IP_ADDRESS (Internal IP for LB): ${RESET_FORMAT}" STATIC_IP_ADDRESS

if [ -z "$STATIC_IP_ADDRESS" ]; then
  echo "${RED_TEXT}Error: You must enter an IP address!${RESET_FORMAT}"
  exit 1
fi

# Fetch Zone and Region
echo "${BLUE_TEXT}Fetching default Zone and Region...${RESET_FORMAT}"
ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

echo "${BLUE_TEXT}Zone set to: $ZONE${RESET_FORMAT}"
echo "${BLUE_TEXT}Region set to: $REGION${RESET_FORMAT}"
echo

# ====================================================
# STEP 2: BACKEND SETUP
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 2: Creating Backend Startup Script${RESET_FORMAT}"

# Creating backend.sh using heredoc
cat << 'EOF' > backend.sh
#! /bin/bash
sudo chmod -R 777 /usr/local/sbin/
sudo cat << 'PY_SCRIPT' > /usr/local/sbin/serveprimes.py
import http.server
def is_prime(a): return a!=1 and all(a % i for i in range(2,int(a**0.5)+1))
class myHandler(http.server.BaseHTTPRequestHandler):
  def do_GET(s):
    s.send_response(200)
    s.send_header("Content-type", "text/plain")
    s.end_headers()
    try:
        # Check if path has content, default to 1 if empty
        val = int(s.path[1:]) if len(s.path) > 1 else 1
        s.wfile.write(bytes(str(is_prime(val)).encode("utf-8")))
    except ValueError:
        s.wfile.write(bytes("False".encode("utf-8")))
http.server.HTTPServer(("",80),myHandler).serve_forever()
PY_SCRIPT
nohup python3 /usr/local/sbin/serveprimes.py >/dev/null 2>&1 &
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Instance Template 'primecalc'...${RESET_FORMAT}"
gcloud compute instance-templates create primecalc \
--metadata-from-file startup-script=backend.sh \
--no-address --tags backend --machine-type=e2-medium --quiet

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Backend Firewall Rule...${RESET_FORMAT}"
# Note: Adjust source-ranges if your subnet differs from 10.142.0.0/20
gcloud compute firewall-rules create http --network default --allow=tcp:80 \
--source-ranges 10.128.0.0/9 --target-tags backend --quiet

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Managed Instance Group 'backend'...${RESET_FORMAT}"
gcloud compute instance-groups managed create backend \
--size 3 \
--template primecalc \
--zone $ZONE --quiet

echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Autoscaling...${RESET_FORMAT}"
gcloud compute instance-groups managed set-autoscaling backend \
--target-cpu-utilization 0.8 --min-num-replicas 3 \
--max-num-replicas 10 --zone $ZONE --quiet

# ====================================================
# STEP 3: LOAD BALANCER CONFIGURATION
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Configuring Internal Load Balancer${RESET_FORMAT}"

echo "${BLUE_TEXT}Creating Health Check...${RESET_FORMAT}"
gcloud compute health-checks create http ilb-health --request-path /2 --quiet

echo "${BLUE_TEXT}Creating Backend Service...${RESET_FORMAT}"
gcloud compute backend-services create prime-service \
--load-balancing-scheme internal --region=$REGION \
--protocol tcp --health-checks ilb-health --quiet

echo "${BLUE_TEXT}Adding Backend Group to Service...${RESET_FORMAT}"
gcloud compute backend-services add-backend prime-service \
--instance-group backend --instance-group-zone=$ZONE \
--region=$REGION --quiet

echo "${BLUE_TEXT}Creating Forwarding Rule (IP: $STATIC_IP_ADDRESS)...${RESET_FORMAT}"
gcloud compute forwarding-rules create prime-lb \
--load-balancing-scheme internal \
--ports 80 --network default \
--region=$REGION --address $STATIC_IP_ADDRESS \
--backend-service prime-service --quiet

# ====================================================
# STEP 4: FRONTEND SETUP
# ====================================================
echo "${BLUE_TEXT}${BOLD_TEXT}Step 4: Creating Frontend Startup Script${RESET_FORMAT}"

# Creating frontend.sh and injecting the STATIC_IP_ADDRESS
cat <<EOF > frontend.sh
#! /bin/bash
sudo chmod -R 777 /usr/local/sbin/
sudo cat << 'PY_SCRIPT' > /usr/local/sbin/getprimes.py
import urllib.request
from multiprocessing.dummy import Pool as ThreadPool
import http.server

# Using the Internal LB IP provided by user
PREFIX="http://$STATIC_IP_ADDRESS/" 

def get_url(number):
    try:
        return urllib.request.urlopen(PREFIX+str(number)).read().decode('utf-8')
    except:
        return "False"

class myHandler(http.server.BaseHTTPRequestHandler):
  def do_GET(s):
    s.send_response(200)
    s.send_header("Content-type", "text/html")
    s.end_headers()
    i = int(s.path[1:]) if (len(s.path)>1) else 1
    s.wfile.write("<html><body><table>".encode('utf-8'))
    pool = ThreadPool(10)
    results = pool.map(get_url,range(i,i+100))
    for x in range(0,100):
      if not (x % 10): s.wfile.write("<tr>".encode('utf-8'))
      if results[x]=="True":
        s.wfile.write("<td bgcolor='#00ff00'>".encode('utf-8'))
      else:
        s.wfile.write("<td bgcolor='#ff0000'>".encode('utf-8'))
      s.wfile.write(str(x+i).encode('utf-8')+"</td> ".encode('utf-8'))
      if not ((x+1) % 10): s.wfile.write("</tr>".encode('utf-8'))
    s.wfile.write("</table></body></html>".encode('utf-8'))
http.server.HTTPServer(("",80),myHandler).serve_forever()
PY_SCRIPT
nohup python3 /usr/local/sbin/getprimes.py >/dev/null 2>&1 &
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Frontend Instance...${RESET_FORMAT}"
gcloud compute instances create frontend --zone=$ZONE \
--metadata-from-file startup-script=frontend.sh \
--tags frontend --machine-type=e2-standard-2 --quiet

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Frontend Firewall Rule...${RESET_FORMAT}"
gcloud compute firewall-rules create http2 --network default --allow=tcp:80 \
--source-ranges 0.0.0.0/0 --target-tags frontend --quiet

# ====================================================
# COMPLETION FOOTER
# ====================================================
echo
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}          LAB COMPLETED SUCCESSFULLY!                         ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}==============================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🙏 Thanks for learning with Nikhil Vaghela${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}📢 Subscribe for more Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Nikhil-Vaghela0716${RESET_FORMAT}"
echo
