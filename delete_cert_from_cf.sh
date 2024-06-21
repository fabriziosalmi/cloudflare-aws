#!/bin/bash

# Load configuration
CONFIG_FILE="config/CF_api.conf"
CERT_ID=""

while getopts "c:z:t:i:" opt; do
  case ${opt} in
    c) CONFIG_FILE=$OPTARG ;;
    z) ZONEID=$OPTARG ;;
    t) BEARER_TOKEN=$OPTARG ;;
    i) CERT_ID=$OPTARG ;;
    \?) echo "Usage: $0 [-c CONFIG_FILE] [-z ZONEID] [-t BEARER_TOKEN] [-i CERT_ID]"
        exit 1 ;;
  esac
done

source $CONFIG_FILE

# Validate required parameters
if [ -z "$ZONEID" ] || [ -z "$BEARER_TOKEN" ] || [ -z "$CERT_ID" ]; then
  echo "ZONEID, BEARER_TOKEN, and CERT_ID are required parameters."
  exit 1
fi

# Logging setup
LOGFILE="logs/delete_cert_from_cf.log"
mkdir -p logs

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

error() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE >&2
  exit 1
}

log "Deleting certificate $CERT_ID from Cloudflare..."

DELETE_RESPONSE=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONEID/origin_tls_client_auth/ca/$CERT_ID" \
     -H "Authorization: Bearer $BEARER_TOKEN")

if echo $DELETE_RESPONSE | grep -q "\"success\":true"; then
  log "Certificate deleted successfully."
else
  error "Failed to delete certificate: $DELETE_RESPONSE"
fi
