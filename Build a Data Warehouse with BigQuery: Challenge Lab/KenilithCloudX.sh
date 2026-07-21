#!/bin/bash

# Text Colors
BLACK_TEXT=$'\033[0;30m'
RED_TEXT=$'\033[0;31m'
GREEN_TEXT=$'\033[0;32m'
YELLOW_TEXT=$'\033[0;33m'
BLUE_TEXT=$'\033[0;34m'
MAGENTA_TEXT=$'\033[0;35m'
CYAN_TEXT=$'\033[0;36m'
WHITE_TEXT=$'\033[0;37m'

# Bright Colors
BRIGHT_RED_TEXT=$'\033[0;91m'
BRIGHT_GREEN_TEXT=$'\033[0;92m'
BRIGHT_YELLOW_TEXT=$'\033[0;93m'
BRIGHT_BLUE_TEXT=$'\033[0;94m'
BRIGHT_MAGENTA_TEXT=$'\033[0;95m'
BRIGHT_CYAN_TEXT=$'\033[0;96m'
BRIGHT_WHITE_TEXT=$'\033[0;97m'

# Formatting
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                  🚀 GOOGLE CLOUD LAB | KenilithCloudX            ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo


set -e

export DATASET_NAME_1="covid"
export DATASET_NAME_2="covid_data"

# ==============================
# Task 1: Create Dataset and Partitioned Table
# ==============================

echo "TASK 1: Creating COVID dataset and partitioned table..."

bq mk --dataset "${DEVSHELL_PROJECT_ID}:${DATASET_NAME_1}"

sleep 10

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE ${DATASET_NAME_1}.oxford_policy_tracker
PARTITION BY date
OPTIONS(
  partition_expiration_days=2175,
  description='oxford_policy_tracker table in the COVID 19 Government Response public dataset with expiry time set to 2175 days.'
) AS
SELECT *
FROM \`bigquery-public-data.covid19_govt_response.oxford_policy_tracker\`
WHERE alpha_3_code NOT IN ('GBR','BRA','CAN','USA')
"

echo "Task 1 completed."
echo

# ==============================
# Task 2: Add Columns
# ==============================

echo "TASK 2: Adding columns..."

bq query --use_legacy_sql=false "
ALTER TABLE ${DATASET_NAME_2}.global_mobility_tracker_data
ADD COLUMN population INT64,
ADD COLUMN country_area FLOAT64,
ADD COLUMN mobility STRUCT<
  avg_retail FLOAT64,
  avg_grocery FLOAT64,
  avg_parks FLOAT64,
  avg_transit FLOAT64,
  avg_workplace FLOAT64,
  avg_residential FLOAT64
>
"

echo "Task 2 completed."
echo

# ==============================
# Task 3: Population Data
# ==============================

echo "TASK 3: Creating population tables..."

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE ${DATASET_NAME_2}.pop_data_2019 AS
SELECT *
FROM \`bigquery-public-data.covid19_ecdc.covid_19_geographic_distribution_worldwide\`
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE ${DATASET_NAME_2}.pop_data_2019_small AS
SELECT
  country_territory_code,
  pop_data_2019
FROM \`${DEVSHELL_PROJECT_ID}.${DATASET_NAME_2}.pop_data_2019\`
GROUP BY
  country_territory_code,
  pop_data_2019
ORDER BY
  country_territory_code
"

bq query --use_legacy_sql=false "
UPDATE \`${DATASET_NAME_2}.consolidate_covid_tracker_data\` t0
SET population = t1.pop_data_2019
FROM \`${DATASET_NAME_2}.pop_data_2019_small\` t1
WHERE TRIM(t0.alpha_3_code) = TRIM(t1.country_territory_code)
"

echo "Task 3 completed."
echo

# ==============================
# Task 4: Update Country Area
# ==============================

echo "TASK 4: Updating country area..."

bq query --use_legacy_sql=false "
UPDATE \`${DATASET_NAME_2}.consolidate_covid_tracker_data\` t0
SET t0.country_area = t1.country_area
FROM \`bigquery-public-data.census_bureau_international.country_names_area\` t1
WHERE t0.country_name = t1.country_name
"

echo "Task 4 completed."
echo

# ==============================
# Bonus Task: Update Mobility
# ==============================

echo "BONUS TASK: Updating mobility..."

bq query --use_legacy_sql=false "
UPDATE \`${DATASET_NAME_2}.consolidate_covid_tracker_data\` t0
SET
  t0.mobility.avg_retail      = t1.avg_retail,
  t0.mobility.avg_grocery     = t1.avg_grocery,
  t0.mobility.avg_parks       = t1.avg_parks,
  t0.mobility.avg_transit     = t1.avg_transit,
  t0.mobility.avg_workplace   = t1.avg_workplace,
  t0.mobility.avg_residential = t1.avg_residential
FROM (
    SELECT
      country_region,
      date,
      AVG(retail_and_recreation_percent_change_from_baseline) AS avg_retail,
      AVG(grocery_and_pharmacy_percent_change_from_baseline) AS avg_grocery,
      AVG(parks_percent_change_from_baseline) AS avg_parks,
      AVG(transit_stations_percent_change_from_baseline) AS avg_transit,
      AVG(workplaces_percent_change_from_baseline) AS avg_workplace,
      AVG(residential_percent_change_from_baseline) AS avg_residential
    FROM \`bigquery-public-data.covid19_google_mobility.mobility_report\`
    GROUP BY country_region, date
) AS t1
WHERE CONCAT(t0.country_name, t0.date) = CONCAT(t1.country_region, t1.date)
"

echo "Bonus task completed."
echo

# ==============================
# Data Quality Checks
# ==============================

echo "Running data quality checks..."

bq query --use_legacy_sql=false "
SELECT DISTINCT country_name
FROM \`${DATASET_NAME_2}.oxford_policy_tracker_worldwide\`
WHERE population IS NULL

UNION ALL

SELECT DISTINCT country_name
FROM \`${DATASET_NAME_2}.oxford_policy_tracker_worldwide\`
WHERE country_area IS NULL

ORDER BY country_name
"

echo

# ==============================
# Create Supporting Tables
# ==============================

echo "Creating country_area_data..."

bq query --use_legacy_sql=false "
CREATE TABLE ${DATASET_NAME_2}.country_area_data AS
SELECT *
FROM \`bigquery-public-data.census_bureau_international.country_names_area\`
"

echo "Creating mobility_data..."

bq query --use_legacy_sql=false "
CREATE TABLE ${DATASET_NAME_2}.mobility_data AS
SELECT *
FROM \`bigquery-public-data.covid19_google_mobility.mobility_report\`
"

# ==============================
# Data Cleaning
# ==============================

echo "Cleaning data..."

bq query --use_legacy_sql=false "
DELETE FROM ${DATASET_NAME_2}.oxford_policy_tracker_by_countries
WHERE population IS NULL
  AND country_area IS NULL
"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}                     ✅ LAB FINISHED SUCCESSFULLY!                ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🙏 Thank you for learning with KenilithCloudX!${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}📢 Subscribe for more hands-on Google Cloud Labs:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@KenilithCloudX${RESET_FORMAT}"
echo

