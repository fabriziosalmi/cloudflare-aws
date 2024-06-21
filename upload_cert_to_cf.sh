#!/bin/bash

# Load configuration
CONFIG_FILE="config/CF_api.conf"
CERT_ID=""
CERT_FILE="alb-cert.pem"
KEY_FILE="alb-key.pem"

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
if [ -z "$ZONEID" ] || [ -z "$BEARER_TOKEN" ]; then
  echo "ZONEID and BEARER_TOKEN are required parameters."
  exit 1
fi

# Logging setup
LOGFILE="logs/upload_cert_to_cf.log"
mkdir -p logs

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

error() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE >&2
  exit 1
}

log "Uploading certificate to Cloudflare..."

UPLOAD_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONEID/origin_tls_client_auth/ca" \
     -H "Authorization: Bearer $BEARER_TOKEN" \
     -H "Content-Type: application/json" \
     --data "{\"certificate\": \"$(cat $CERT_FILE)\", \"private_key\": \"$(cat $KEY_FILE)\", \"type\": \"origin\", \"name\": \"$CERT_ID\"}")

if echo $UPLOAD_RESPONSE | grep -q "\"success\":true"; then
  log "Certificate uploaded successfully."
else
  error "Failed to upload certificate: $UPLOAD_RESPONSE"
fi
