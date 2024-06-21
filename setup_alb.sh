#!/bin/bash

# Define log files
LOGFILE="alb_setup_log.txt"
DEBUG_LOGFILE="alb_setup_debug_log.txt"

# Default configuration values
CONFIG_FILE="aws_config.conf"
VPC_ID=""
SUBNET_IDS=""
ALB_NAME=""

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
    echo "Usage: $0 [-c CONFIG_FILE] [-v VPC_ID] [-s SUBNET_IDS] [-n ALB_NAME]"
    exit 1
}

# Parse command-line arguments
while getopts "c:v:s:n:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        v) VPC_ID="$OPTARG" ;;
        s) SUBNET_IDS="$OPTARG" ;;
        n) ALB_NAME="$OPTARG" ;;
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
VPC_ID=${VPC_ID:-$(printenv VPC_ID)}
SUBNET_IDS=${SUBNET_IDS:-$(printenv SUBNET_IDS)}
ALB_NAME=${ALB_NAME:-$(printenv ALB_NAME)}

# Ensure required variables are set
if [ -z "$VPC_ID" ] || [ -z "$SUBNET_IDS" ] || [ -z "$ALB_NAME" ]; then
    log_error "VPC_ID, SUBNET_IDS, and ALB_NAME must be set. Use -v, -s, and -n to provide them or set them in the environment/config file."
    usage
fi

# Create the ALB
log_info "Creating Application Load Balancer (ALB) with name: $ALB_NAME"
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name "$ALB_NAME" \
    --subnets $SUBNET_IDS \
    --security-groups "$SECURITY_GROUP_ID" \
    --scheme internet-facing \
    --type application \
    --output json | jq -r '.LoadBalancers[0].LoadBalancerArn')

if [ $? -eq 0 ]; then
    log_info "Successfully created ALB: $ALB_NAME"
    log_info "ALB ARN: $ALB_ARN"
else
    log_error "Failed to create ALB: $ALB_NAME"
    exit 1
fi

log_info "Script completed successfully."
