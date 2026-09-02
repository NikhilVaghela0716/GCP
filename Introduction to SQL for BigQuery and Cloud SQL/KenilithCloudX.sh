#!/bin/bash
BLUE_TEXT=$(tput setaf 4)
RED_TEXT=$(tput setaf 1)
BOLD_TEXT=$(tput bold)
RESET_FORMAT=$(tput sgr0)

clear

# ====================================================
# PRE-FLIGHT CHECKS
# =========================
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}              🚀 GOOGLE CLOUD LAB | KenilithCloudX               ${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo


read -p "$(echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter your GCP REGION (example: us-central1, asia-south1): ${RESET_FORMAT}")" REGION

echo "${GREEN_TEXT}${BOLD_TEXT}Using REGION: ${RESET_FORMAT}$REGION"

gsutil mb gs://$DEVSHELL_PROJECT_ID

curl -L -o start_station_name.csv \
https://raw.githubusercontent.com/Arcade-helper/Solutions/main/Introduction%20to%20SQL%20for%20BigQuery%20and%20Cloud%20SQL/start_station_name.csv

curl -L -o end_station_name.csv \
https://raw.githubusercontent.com/Arcade-helper/Solutions/main/Introduction%20to%20SQL%20for%20BigQuery%20and%20Cloud%20SQL/end_station_name.csv

gsutil cp start_station_name.csv gs://$DEVSHELL_PROJECT_ID/
gsutil cp end_station_name.csv gs://$DEVSHELL_PROJECT_ID/

gcloud sql instances create my-demo \
    --database-version=MYSQL_8_0 \
    --region=$REGION \
    --tier=db-f1-micro \
    --root-password=kenilith


# ====================================================
# COMPLETION FOOTER
# ====================================================
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}                     ✅ LAB FINISHED!                             ${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo -e "${CYAN_TEXT}${BOLD_TEXT}🎉 Congratulations! Your Google Cloud Lab has been completed.${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}🙏 Thank you for learning with KenilithCloudX!${RESET_FORMAT}"
echo -e "${YELLOW_TEXT}${BOLD_TEXT}📢 Subscribe for more hands-on Google Cloud Labs:${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudx${RESET_FORMAT}"
echo
