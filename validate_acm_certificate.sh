#!/bin/bash

# Define log files
LOGFILE="acm_validation_log.txt"
DEBUG_LOGFILE="acm_validation_debug_log.txt"

# Default configuration values
CONFIG_FILE="aws_config.conf"
DOMAIN_NAME=""
CF_HOSTNAME=""
ZONEID=""
BEARER_TOKEN=""

# Function to log info messages
log_info() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

# Function to log error messages
log_error() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE
}

# Function to log debug messages
log_debug() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") [DEBUG] $1" >> $DEBUG_LOGFILE
}

# Function to display usage information
usage() {
    echo "Usage: $0 [-c CONFIG_FILE] [-d DOMAIN_NAME] [-h CF_HOSTNAME] [-z ZONEID] [-t BEARER_TOKEN]"
    exit 1
}

# Parse command-line arguments
while getopts "c:d:h:z:t:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        d) DOMAIN_NAME="$OPTARG" ;;
        h) CF_HOSTNAME="$OPTARG" ;;
        z) ZONEID="$OPTARG" ;;
        t) BEARER_TOKEN="$OPTARG" ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

# Load configuration from file if it exists
if [ -f $CONFIG_FILE ]; then
    . $CONFIG_FILE
    log_info "Loaded configuration from $CONFIG_FILE."
else
    log_info "Configuration file $CONFIG_FILE not found. Using defaults and environment variables."
fi

# Check if required variables are set, either by command-line arguments, environment variables, or config file
DOMAIN_NAME=${DOMAIN_NAME:-$(printenv DOMAIN_NAME)}
CF_HOSTNAME=${CF_HOSTNAME:-$(printenv CF_HOSTNAME)}
ZONEID=${ZONEID:-$(printenv ZONEID)}
BEARER_TOKEN=${BEARER_TOKEN:-$(printenv BEARER_TOKEN)}

# Ensure required variables are set
if [ -z "$DOMAIN_NAME" ] || [ -z "$CF_HOSTNAME" ] || [ -z "$ZONEID" ] || [ -z "$BEARER_TOKEN" ]; then
    log_error "DOMAIN_NAME, CF_HOSTNAME, ZONEID, and BEARER_TOKEN must be set. Use the respective options or environment variables to provide them."
    usage
fi

# Request ACM certificate
log_info "Requesting ACM certificate for domain: $DOMAIN_NAME"
CERTIFICATE_ARN=$(aws acm request-certificate \
    --domain-name "$DOMAIN_NAME" \
    --validation-method DNS \
    --output json | jq -r '.CertificateArn')

if [ $? -eq 0 ]; then
    log_info "Successfully requested ACM certificate for domain: $DOMAIN_NAME"
    log_info "Certificate ARN: $CERTIFICATE_ARN"
else
    log_error "Failed to request ACM certificate for domain: $DOMAIN_NAME"
    exit 1
fi

# Retrieve DNS validation details
log_info "Retrieving DNS validation details for certificate: $CERTIFICATE_ARN"
DNS_RECORDS=$(aws acm describe-certificate \
    --certificate-arn "$CERTIFICATE_ARN" \
    --output json | jq -r '.Certificate.DomainValidationOptions[] | select(.DomainName == "'"$DOMAIN_NAME"'") | .ResourceRecord')

if [ $? -eq 0 ]; then
    log_info "Successfully retrieved DNS validation details for certificate: $CERTIFICATE_ARN"
else
    log_error "Failed to retrieve DNS validation details for certificate: $CERTIFICATE_ARN"
    exit 1
fi

# Extract DNS record name and value
DNS_NAME=$(echo "$DNS_RECORDS" | jq -r '.Name')
DNS_VALUE=$(echo "$DNS_RECORDS" | jq -r '.Value')

# Create DNS TXT record in Cloudflare
log_info "Creating DNS TXT record in Cloudflare for validation"
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records" \
    -H "Authorization: Bearer $BEARER_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{
        "type": "TXT",
        "name": "'"$DNS_NAME"'",
        "content": "'"$DNS_VALUE"'",
        "ttl": 120
    }' | jq .

if [ $? -eq 0 ]; then
    log_info "Successfully created DNS TXT record in Cloudflare for validation"
else
    log_error "Failed to create DNS TXT record in Cloudflare for validation"
    exit 1
fi

log_info "Waiting for DNS validation..."
sleep 60  # Wait for DNS propagation

# Check certificate status
log_info "Checking certificate validation status"
CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn "$CERTIFICATE_ARN" \
    --output json | jq -r '.Certificate.Status')

if [ "$CERT_STATUS" == "ISSUED" ]; then
    log_info "Certificate validated and issued successfully"
else
    log_error "Certificate validation failed or still pending. Current status: $CERT_STATUS"
    exit 1
fi

log_info "Script completed successfully."
