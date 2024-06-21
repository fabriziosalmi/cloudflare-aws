#!/bin/bash

# Define log files
LOGFILE="s3_trust_store_log.txt"
DEBUG_LOGFILE="s3_trust_store_debug_log.txt"

# Default configuration values
CONFIG_FILE="aws_config.conf"
BUCKET_NAME=""
DIRECTORY_PATH=""

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
    echo "Usage: $0 [-c CONFIG_FILE] [-b BUCKET_NAME] [-d DIRECTORY_PATH]"
    exit 1
}

# Parse command-line arguments
while getopts "c:b:d:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        b) BUCKET_NAME="$OPTARG" ;;
        d) DIRECTORY_PATH="$OPTARG" ;;
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
BUCKET_NAME=${BUCKET_NAME:-$(printenv BUCKET_NAME)}
DIRECTORY_PATH=${DIRECTORY_PATH:-$(printenv DIRECTORY_PATH)}

# Ensure required variables are set
if [ -z "$BUCKET_NAME" ] || [ -z "$DIRECTORY_PATH" ]; then
    log_error "BUCKET_NAME and DIRECTORY_PATH must be set. Use -b and -d to provide them or set them in the environment/config file."
    usage
fi

# Create the S3 bucket
log_info "Creating S3 bucket: $BUCKET_NAME"
aws s3 mb "s3://$BUCKET_NAME" --region us-east-1

if [ $? -eq 0 ]; then
    log_info "Successfully created S3 bucket: $BUCKET_NAME"
else
    log_error "Failed to create S3 bucket: $BUCKET_NAME"
    exit 1
fi

# Upload CA certificates to the S3 bucket
log_info "Uploading CA certificates from directory: $DIRECTORY_PATH to bucket: $BUCKET_NAME"
aws s3 cp "$DIRECTORY_PATH" "s3://$BUCKET_NAME/" --recursive

if [ $? -eq 0 ]; then
    log_info "Successfully uploaded CA certificates to S3 bucket: $BUCKET_NAME"
else
    log_error "Failed to upload CA certificates to S3 bucket: $BUCKET_NAME"
    exit 1
fi

# Generate the CA URI
CA_URI="s3://$BUCKET_NAME/"
log_info "Generated CA URI for mTLS: $CA_URI"

log_info "Script completed successfully."
