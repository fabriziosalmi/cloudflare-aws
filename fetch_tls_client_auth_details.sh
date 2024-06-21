#!/bin/bash

# Load configuration
CONFIG_FILE="config/CF_api.conf"

while getopts "c:z:t:" opt; do
  case ${opt} in
    c) CONFIG_FILE=$OPTARG ;;
    z) ZONEID=$OPTARG ;;
    t) BEARER_TOKEN=$OPTARG ;;
    \?) echo "Usage: $0 [-c CONFIG_FILE] [-z ZONEID] [-t BEARER_TOKEN]"
        exit 1 ;;
  esac
done

source $CONFIG_FILE

# Validate required parameters
if [ -z "$ZONEID" ] || [ -z "$BEARER_TOKEN" ]; then
  echo "ZONEID and BEARER_TOKEN are required parameters."
  exit 1
fi

# Logging setup
LOGFILE="logs/fetch_tls_client_auth_details.log"
mkdir -p logs

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

error() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE >&2
  exit 1
}

log "Fetching TLS client authentication details from Cloudflare..."

AUTH_DETAILS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONEID/origin_tls_client_auth" \
     -H "Authorization: Bearer $BEARER_TOKEN")

if echo $AUTH_DETAILS | grep -q "\"success\":true"; then
  log "TLS client authentication details fetched successfully."
  echo $AUTH_DETAILS | jq '.result'
else
  error "Failed to fetch TLS client authentication details: $AUTH_DETAILS"
fi
