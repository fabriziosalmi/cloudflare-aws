#!/bin/bash

# Load configuration
CONFIG_FILE="config/aws_config.conf"
SECURITY_GROUP_NAME="my-security-group"
VPC_ID=""

while getopts "c:n:v:" opt; do
  case ${opt} in
    c) CONFIG_FILE=$OPTARG ;;
    n) SECURITY_GROUP_NAME=$OPTARG ;;
    v) VPC_ID=$OPTARG ;;
    \?) echo "Usage: $0 [-c CONFIG_FILE] [-n SECURITY_GROUP_NAME] [-v VPC_ID]"
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
LOGFILE="logs/setup_security_groups.log"
mkdir -p logs

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

error() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE >&2
  exit 1
}

log "Creating security group $SECURITY_GROUP_NAME in VPC $VPC_ID..."

SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for ALB" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text) || error "Failed to create security group"

log "Security group created successfully: $SECURITY_GROUP_ID"

log "Adding inbound rules to the security group..."

aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 || error "Failed to add inbound rule to security group"

log "Security group configured successfully: $SECURITY_GROUP_ID"
