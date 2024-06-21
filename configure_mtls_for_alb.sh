#!/bin/bash

# Define log files
LOGFILE="mtls_config_log.txt"
DEBUG_LOGFILE="mtls_config_debug_log.txt"

# Default configuration values
CONFIG_FILE="aws_config.conf"
LISTENER_ARN=""
TRUST_STORE_ARN=""

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
    echo "Usage: $0 [-c CONFIG_FILE] [-l LISTENER_ARN] [-t TRUST_STORE_ARN]"
    exit 1
}

# Parse command-line arguments
while getopts "c:l:t:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        l) LISTENER_ARN="$OPTARG" ;;
        t) TRUST_STORE_ARN="$OPTARG" ;;
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
LISTENER_ARN=${LISTENER_ARN:-$(printenv LISTENER_ARN)}
TRUST_STORE_ARN=${TRUST_STORE_ARN:-$(printenv TRUST_STORE_ARN)}

# Ensure required variables are set
if [ -z "$LISTENER_ARN" ] || [ -z "$TRUST_STORE_ARN" ]; then
    log_error "LISTENER_ARN and TRUST_STORE_ARN must be set. Use -l and -t to provide them or set them in the environment/config file."
    usage
fi

# Configure mTLS for the listener
log_info "Configuring mTLS for listener: $LISTENER_ARN with trust store: $TRUST_STORE_ARN"
aws elbv2 modify-listener \
    --listener-arn "$LISTENER_ARN" \
    --ssl-policy ELBSecurityPolicy-FS-1-2-Res-2019-08 \
    --certificates CertificateArn=$CERTIFICATE_ARN \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
    --mutual-authentication PolicyName="mTLS-Policy",TrustStoreArn=$TRUST_STORE_ARN \
    --output json

if [ $? -eq 0 ]; then
    log_info "Successfully configured mTLS for listener: $LISTENER_ARN"
else
    log_error "Failed to configure mTLS for listener: $LISTENER_ARN"
    exit 1
fi

log_info "Script completed successfully."
