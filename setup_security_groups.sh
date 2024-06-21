#!/bin/bash

# Define log files
LOGFILE="security_group_setup_log.txt"
DEBUG_LOGFILE="security_group_setup_debug_log.txt"

# Default configuration values
CONFIG_FILE="aws_config.conf"
SECURITY_GROUP_NAME=""
VPC_ID=""

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
    echo "Usage: $0 [-c CONFIG_FILE] [-n SECURITY_GROUP_NAME] [-v VPC_ID]"
    exit 1
}

# Parse command-line arguments
while getopts "c:n:v:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        n) SECURITY_GROUP_NAME="$OPTARG" ;;
        v) VPC_ID="$OPTARG" ;;
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
SECURITY_GROUP_NAME=${SECURITY_GROUP_NAME:-$(printenv SECURITY_GROUP_NAME)}
VPC_ID=${VPC_ID:-$(printenv VPC_ID)}

# Ensure required variables are set
if [ -z "$SECURITY_GROUP_NAME" ] || [ -z "$VPC_ID" ]; then
    log_error "SECURITY_GROUP_NAME and VPC_ID must be set. Use -n and -v to provide them or set them in the environment/config file."
    usage
fi

# Create the security group
log_info "Creating security group: $SECURITY_GROUP_NAME in VPC: $VPC_ID"
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name "$SECURITY_GROUP_NAME" \
    --description "Security group for ALB and associated instances" \
    --vpc-id "$VPC_ID" \
    --output json | jq -r '.GroupId')

if [ $? -eq 0 ]; then
    log_info "Successfully crea
