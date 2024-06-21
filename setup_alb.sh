#!/bin/bash

# Define log files
LOGFILE="alb_setup_log.txt"
DEBUG_LOGFILE="alb_setup_debug_log.txt"

# Default configuration values
CONFIG_FILE="aws_config.conf"
VPC_ID=""
SUBNET_IDS=""
ALB_NAME=""
SECURITY_GROUP_ID=""
TARGET_GROUP_ARN=""
CERTIFICATE_ARN=""
CA_URI=""

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
    echo "Usage: $0 [-c CONFIG_FILE] [-v VPC_ID] [-s SUBNET_IDS] [-n ALB_NAME] [-g SECURITY_GROUP_ID] [-t TARGET_GROUP_ARN] [-l CERTIFICATE_ARN] [-u CA_URI]"
    exit 1
}

# Parse command-line arguments
while getopts "c:v:s:n:g:t:l:u:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        v) VPC_ID="$OPTARG" ;;
        s) SUBNET_IDS="$OPTARG" ;;
        n) ALB_NAME="$OPTARG" ;;
        g) SECURITY_GROUP_ID="$OPTARG" ;;
        t) TARGET_GROUP_ARN="$OPTARG" ;;
        l) CERTIFICATE_ARN="$OPTARG" ;;
        u) CA_URI="$OPTARG" ;;
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
SECURITY_GROUP_ID=${SECURITY_GROUP_ID:-$(printenv SECURITY_GROUP_ID)}
TARGET_GROUP_ARN=${TARGET_GROUP_ARN:-$(printenv TARGET_GROUP_ARN)}
CERTIFICATE_ARN=${CERTIFICATE_ARN:-$(printenv CERTIFICATE_ARN)}
CA_URI=${CA_URI:-$(printenv CA_URI)}

# Ensure required variables are set
if [ -z "$VPC_ID" ] || [ -z "$SUBNET_IDS" ] || [ -z "$ALB_NAME" ] || [ -z "$SECURITY_GROUP_ID" ] || [ -z "$TARGET_GROUP_ARN" ] || [ -z "$CERTIFICATE_ARN" ] || [ -z "$CA_URI" ]; then
    log_error "VPC_ID, SUBNET_IDS, ALB_NAME, SECURITY_GROUP_ID, TARGET_GROUP_ARN, CERTIFICATE_ARN, and CA_URI must be set. Use the respective options or environment variables to provide them."
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

# Create the listener
log_info "Creating listener for ALB: $ALB_ARN on port: 443"
LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn "$ALB_ARN" \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=$CERTIFICATE_ARN \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
    --ssl-policy ELBSecurityPolicy-TLS-1-2-2017-01 \
    --output json | jq -r '.Listeners[0].ListenerArn')

if [ $? -eq 0 ]; then
    log_info "Successfully created listener on port: 443"
    log_info "Listener ARN: $LISTENER_ARN"
else
    log_error "Failed to create listener for ALB: $ALB_ARN on port: 443"
    exit 1
fi

# Configure mTLS for the listener
log_info "Configuring mTLS for listener: $LISTENER_ARN"
aws elbv2 modify-listener \
    --listener-arn "$LISTENER_ARN" \
    --ssl-policy ELBSecurityPolicy-FS-1-2-Res-2019-08 \
    --certificates CertificateArn=$CERTIFICATE_ARN \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
    --mutual-authentication PolicyName="mTLS-Policy",TrustStoreUri=$CA_URI \
    --output json

if [ $? -eq 0 ]; then
    log_info "Successfully configured mTLS for listener: $LISTENER_ARN"
else
    log_error "Failed to configure mTLS for listener: $LISTENER_ARN"
    exit 1
fi

log_info "Script completed successfully."
