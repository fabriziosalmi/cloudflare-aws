#!/bin/bash

# Define log files
LOGFILE="log.txt"
DEBUG_LOGFILE="debug_log.txt"

# Default configuration values
CONFIG_FILE="CF_api.conf"
ZONEID=""
BEARER_TOKEN=""
CF_HOSTNAME=""

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
    echo "Usage: $0 [-c CONFIG_FILE] [-z ZONEID] [-t BEARER_TOKEN] [-h CF_HOSTNAME] [CERT_ID]"
    exit 1
}

# Parse command-line arguments
while getopts "c:z:t:h:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        z) ZONEID="$OPTARG" ;;
        t) BEARER_TOKEN="$OPTARG" ;;
        h) CF_HOSTNAME="$OPTARG" ;;
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
CF_HOSTNAME=${CF_HOSTNAME:-$(printenv CF_HOSTNAME)}

# Ensure required variables are set
if [ -z "$ZONEID" ] || [ -z "$BEARER_TOKEN" ] || [ -z "$CF_HOSTNAME" ]; then
    log_error "ZONEID, BEARER_TOKEN, and CF_HOSTNAME must be set. Use -z, -t, and -h to provide them or set them in the environment/config file."
    usage
fi

# Function to get the certificate ID
get_cert_id() {
    local cert_serial_file="cert.serial"

    if [ -f $cert_serial_file ]; then
        log_info "cert.serial found. Retrieving certificate ID."
        local cert_serial
        cert_serial=$(cat $cert_serial_file)
        CERTID=$(./get_certs.sh | jq -r '.result[] | select(.serial_number == "'"$cert_serial"'") | .id')
        if [ -z "$CERTID" ]; then
            log_error "Certificate ID not found for serial number $cert_serial."
            exit 1
        fi
    else
        if [ -z "$1" ]; then
            log_error "CERT_ID is missing. Provide it as an argument or ensure cert.serial exists."
            usage
        fi
        CERTID=$1
    fi
}

# Trap to catch errors and clean up if script exits unexpectedly
trap 'log_error "Script terminated unexpectedly."; exit 1' ERR

# Main script execution
CERT_ID_ARG="$1"
get_cert_id "$CERT_ID_ARG"

log_info "Using CERTID: $CERTID for updating Cloudflare configuration."

response=$(curl -s --request PUT \
--url "https://api.cloudflare.com/client/v4/zones/$ZONEID/origin_tls_client_auth/hostnames" \
-H 'Content-Type: application/json' \
-H "Authorization: Bearer $BEARER_TOKEN" \
--data '{
"config": [
{
"enabled": true,
"cert_id": "'"$CERTID"'",
"hostname": "'"$CF_HOSTNAME"'"
}
]
}' | jq .)

if [ $? -eq 0 ]; then
    log_info "Successfully updated Cloudflare configuration."
    echo "$response" | tee -a $LOGFILE
else
    log_error "Failed to update Cloudflare configuration."
    exit 1
fi

log_info "Script completed successfully."
