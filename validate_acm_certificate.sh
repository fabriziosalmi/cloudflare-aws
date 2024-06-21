#!/bin/bash

# Load configuration
CONFIG_FILE="config/aws_config.conf"
DOMAIN_NAME=""
CF_HOSTNAME=""
ZONEID=""
BEARER_TOKEN=""

while getopts "c:d:h:z:t:" opt; do
  case ${opt} in
    c) CONFIG_FILE=$OPTARG ;;
    d) DOMAIN_NAME=$OPTARG ;;
    h) CF_HOSTNAME=$OPTARG ;;
    z) ZONEID=$OPTARG ;;
    t) BEARER_TOKEN=$OPTARG ;;
    \?) echo "Usage: $0 [-c CONFIG_FILE] [-d DOMAIN_NAME] [-h CF_HOSTNAME] [-z ZONEID] [-t BEARER_TOKEN]"
        exit 1 ;;
  esac
done

source $CONFIG_FILE

# Validate required parameters
if [ -z "$DOMAIN_NAME" ] || [ -z "$CF_HOSTNAME" ] || [ -z "$ZONEID" ] || [ -z "$BEARER_TOKEN" ]; then
  echo "DOMAIN_NAME, CF_HOSTNAME, ZONEID, and BEARER_TOKEN are required parameters."
  exit 1
fi

# Logging setup
LOGFILE="logs/validate_acm_certificate.log"
mkdir -p logs

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

error() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE >&2
  exit 1
}

log "Requesting ACM certificate for domain $DOMAIN_NAME..."

CERTIFICATE_ARN=$(aws acm request-certificate \
    --domain-name $DOMAIN_NAME \
    --validation-method DNS \
    --query 'CertificateArn' \
    --output text) || error "Failed to request ACM certificate"

log "Certificate requested successfully: $CERTIFICATE_ARN"

log "Fetching DNS validation record from ACM..."

VALIDATION_OPTIONS=$(aws acm describe-certificate \
    --certificate-arn $CERTIFICATE_ARN \
    --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
    --output json) || error "Failed to fetch DNS validation record"

log "Adding DNS validation record to Cloudflare..."

RECORD_NAME=$(echo $VALIDATION_OPTIONS | jq -r '.Name')
RECORD_VALUE=$(echo $VALIDATION_OPTIONS | jq -r '.Value')
RECORD_TYPE=$(echo $VALIDATION_OPTIONS | jq -r '.Type')

ADD_RECORD_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records" \
    -H "Authorization: Bearer $BEARER_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"$RECORD_TYPE\",\"name\":\"$RECORD_NAME\",\"content\":\"$RECORD_VALUE\",\"ttl\":120}")

if echo $ADD_RECORD_RESPONSE | grep -q "\"success\":true"; then
  log "DNS validation record added successfully to Cloudflare."
else
  error "Failed to add DNS validation record to Cloudflare: $ADD_RECORD_RESPONSE"
fi

log "Waiting for certificate validation..."

VALIDATION_STATUS="PENDING_VALIDATION"
while [ "$VALIDATION_STATUS" != "SUCCESS" ]; do
  VALIDATION_STATUS=$(aws acm describe-certificate \
      --certificate-arn $CERTIFICATE_ARN \
      --query 'Certificate.DomainValidationOptions[0].ValidationStatus' \
      --output text)
  log "Current validation status: $VALIDATION_STATUS"
  sleep 30
done

log "Certificate validated successfully: $CERTIFICATE_ARN"
