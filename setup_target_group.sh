#!/bin/bash

# Define log files
LOGFILE="target_group_setup_log.txt"
DEBUG_LOGFILE="target_group_setup_debug_log.txt"

# Default configuration values
CONFIG_FILE="aws_config.conf"
TARGET_GROUP_NAME=""
VPC_ID=""
PROTOCOL="HTTP"
PORT=80
TARGET_TYPE="instance"

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
    echo "Usage: $0 [-c CONFIG_FILE] [-n TARGET_GROUP_NAME] [-v VPC_ID] [-p PROTOCOL] [-h PORT] [-t TARGET_TYPE]"
    exit 1
}

# Parse command-line arguments
while getopts "c:n:v:p:h:t:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        n) TARGET_GROUP_NAME="$OPTARG" ;;
        v) VPC_ID="$OPTARG" ;;
        p) PROTOCOL="$OPTARG" ;;
        h) PORT="$OPTARG" ;;
        t) TARGET_TYPE="$OPTARG" ;;
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
TARGET_GROUP_NAME=${TARGET_GROUP_NAME:-$(printenv TARGET_GROUP_NAME)}
VPC_ID=${VPC_ID:-$(printenv VPC_ID)}
PROTOCOL=${PROTOCOL:-$(printenv PROTOCOL)}
PORT=${PORT:-$(printenv PORT)}
TARGET_TYPE=${TARGET_TYPE:-$(printenv TARGET_TYPE)}

# Ensure required variables are set
if [ -z "$TARGET_GROUP_NAME" ] || [ -z "$VPC_ID" ]; then
    log_error "TARGET_GROUP_NAME and VPC_ID must be set. Use -n and -v to provide them or set them in the environment/config file."
    usage
fi

# Create the target group
log_info "Creating target group: $TARGET_GROUP_NAME in VPC: $VPC_ID"
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name "$TARGET_GROUP_NAME" \
    --protocol "$PROTOCOL" \
    --port "$PORT" \
    --vpc-id "$VPC_ID" \
    --target-type "$TARGET_TYPE" \
    --output json | jq -r '.TargetGroups[0].TargetGroupArn')

if [ $? -eq 0 ]; then
    log_info "Successfully created target group: $TARGET_GROUP_NAME"
    log_info "Target Group ARN: $TARGET_GROUP_ARN"
else
    log_error "Failed to create target group: $TARGET_GROUP_NAME"
    exit 1
fi

log_info "Script completed successfully."
