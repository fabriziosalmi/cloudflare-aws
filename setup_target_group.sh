#!/bin/bash

# Load configuration
CONFIG_FILE="config/aws_config.conf"
TARGET_GROUP_NAME="my-target-group"
PROTOCOL="HTTP"
PORT=80
VPC_ID=""
TARGET_TYPE="instance"

while getopts "c:n:v:p:h:t:" opt; do
  case ${opt} in
    c) CONFIG_FILE=$OPTARG ;;
    n) TARGET_GROUP_NAME=$OPTARG ;;
    v) VPC_ID=$OPTARG ;;
    p) PROTOCOL=$OPTARG ;;
    h) PORT=$OPTARG ;;
    t) TARGET_TYPE=$OPTARG ;;
    \?) echo "Usage: $0 [-c CONFIG_FILE] [-n TARGET_GROUP_NAME] [-v VPC_ID] [-p PROTOCOL] [-h PORT] [-t TARGET_TYPE]"
        exit 1 ;;
  esac
done

source $CONFIG_FILE

# Validate required parameters
if [ -z "$VPC_ID" ]; then
  echo "VPC_ID is a required parameter."
  exit 1
fi

# Logging setup
LOGFILE="logs/setup_target_group.log"
mkdir -p logs

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

error() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE >&2
  exit 1
}

log "Creating target group $TARGET_GROUP_NAME in VPC $VPC_ID..."

TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name $TARGET_GROUP_NAME \
    --protocol $PROTOCOL \
    --port $PORT \
    --vpc-id $VPC_ID \
    --target-type $TARGET_TYPE \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text) || error "Failed to create target group"

log "Target group created successfully: $TARGET_GROUP_ARN"
