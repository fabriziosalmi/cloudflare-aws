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
shift $((OPTIND-1))

# Load configuration from file if it exists
if [ -f $CONFIG_FILE ]; then
    . $CONFIG_FILE
    log_info "Loaded configuration from $CONFIG_FILE."
else
    log_info "Configuration file $CONFIG_FILE not found. Using defaults and environment variables."
fi

# Check if required variables are set, either by command-line arguments, environment variables, or config file
ZONEID=${ZONEID:-$(printenv ZONEID)}
BEARER_TOKEN=${BEARER_TOKEN:-$(printenv BEARER_TOKEN)}

# Ensure required variables are set
if [ -z "$ZONEID" ] || [ -z "$BEARER_TOKEN" ]; then
    log_error "ZONEID and BEARER_TOKEN must be set. Use -z and -t to provide them or set them in the environment/config file."
    usage
fi

# Trap to catch errors and clean up if script exits unexpectedly
trap 'log_error "Script terminated unexpectedly."; exit 1' ERR

# Main script execution
log_info "Starting fetch certificates from Cloudflare."

response=$(curl -s --request GET \
--url "https://api.cloudflare.com/client/v4/zones/$ZONEID/origin_tls_client_auth/hostnames/certificates" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $BEARER_TOKEN")

if [ $? -eq 0 ]; then
    log_info "Successfully fetched certificates from Cloudflare API."
    echo "$response" | jq . | tee -a $LOGFILE
    if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
        log_info "Certificates fetched successfully."
    else
        log_error "Failed to fetch certificates. Response: $(echo "$response" | jq -r '.errors[]')"
        exit 1
    fi
else
    log_error "Failed to send GET request to Cloudflare API."
    exit 1
fi

log_info "Script completed successfully."
