#!/bin/bash

# Define log files
LOGFILE="log.txt"
DEBUG_LOGFILE="debug_log.txt"

# Default configuration values
CONFIG_FILE="CF_api.conf"
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
    echo "Usage: $0 [-c CONFIG_FILE] [-z ZONEID] [-t BEARER_TOKEN]"
    exit 1
}

# Parse command-line arguments
while getopts "c:z:t:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        z) ZONEID="$OPTARG" ;;
        t) BEARER_TOKEN="$OPTARG" ;;
        *) usage ;;
    esac
done

# Load configuration from file if it exists
if [ -f $CONFIG_FILE ]; then
    . $CONFIG_FILE
    log_info "Loaded configuration from $CONFIG_FILE."
else
    log_info "Configuration file $CONFIG_FILE not found. Using defaults and environment variables."
fi

# Check if required variables are set, either by command-line arguments, environment variables, or config file
ZONEID=${ZONEID:-${ZONEID_ENV}}
ZONEID=${ZONEID:-$(printenv ZONEID)}
BEARER_TOKEN=${BEARER_TOKEN:-${BEARER_TOKEN_ENV}}
BEARER_TOKEN=${BEARER_TOKEN:-$(printenv BEARER_TOKEN)}

# Ensure required variables are set
if [ -z "$ZONEID" ] || [ -z "$BEARER_TOKEN" ]; then
    log_error "ZONEID and BEARER_TOKEN must be set. Use -z and -t to provide them or set them in the environment/config file."
    usage
fi

# Function to check if required files exist
check_files() {
    for file in "$@"; do
        if [ ! -f "$file" ]; then
            log_error "Required file $file is missing."
            exit 1
        fi
    done
}

# Function to load and format certificate and key
load_and_format_cert_key() {
    local cert_file="$1"
    local key_file="$2"

    log_info "Loading and formatting certificate and key..."
    MYCERT=$(cat "$cert_file" | perl -pe 's/\r?\n/\\n/' | sed -e 's/..$//')
    if [ $? -ne 0 ]; then
        log_error "Failed to load or format certificate from $cert_file."
        exit 1
    fi

    MYKEY=$(cat "$key_file" | perl -pe 's/\r?\n/\\n/' | sed -e 's/..$//')
    if [ $? -ne 0 ]; then
        log_error "Failed to load or format key from $key_file."
        exit 1
    fi

    log_info "Certificate and key loaded and formatted successfully."
}

# Function to push certificate to API
push_certificate_to_api() {
    log_info "Preparing request body and pushing certificate to API..."
    local request_body=$(cat <<EOF
{
  "certificate": "$MYCERT",
  "private_key": "$MYKEY",
  "bundle_method": "ubiquitous"
}
EOF
    )

    response=$(curl -sX POST https://api.cloudflare.com/client/v4/zones/$ZONEID/origin_tls_client_auth/hostnames/certificates \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $BEARER_TOKEN" \
    -d "$request_body" | jq .)

    if [ $? -eq 0 ]; then
        log_info "Certificate pushed to API successfully."
        echo "$response" | tee -a $LOGFILE
    else
        log_error "Failed to push certificate to API."
        exit 1
    fi
}

# Trap to catch errors and clean up if script exits unexpectedly
trap 'log_error "Script terminated unexpectedly."; exit 1' ERR

# Main script execution
check_files "client.crt" "client.key"
load_and_format_cert_key "client.crt" "client.key"
push_certificate_to_api

log_info "Script completed successfully."
