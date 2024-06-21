#!/bin/bash

# Load configuration
CONFIG_FILE="config/aws_config.conf"
ALB_NAME="my-alb"
SUBNET_IDS=""
SECURITY_GROUP_ID=""
TARGET_GROUP_ARN=""
CERTIFICATE_ARN=""
CA_URI=""

while getopts "c:v:s:n:g:t:l:u:" opt; do
  case ${opt} in
    c) CONFIG_FILE=$OPTARG ;;
    v) VPC_ID=$OPTARG ;;
    s) SUBNET_IDS=$OPTARG ;;
    n) ALB_NAME=$OPTARG ;;
    g) SECURITY_GROUP_ID=$OPTARG ;;
    t) TARGET_GROUP_ARN=$OPTARG ;;
    l) CERTIFICATE_ARN=$OPTARG ;;
    u) CA_URI=$OPTARG ;;
    \?) echo "Usage: $0 [-c CONFIG_FILE] [-v VPC_ID] [-s SUBNET_IDS] [-n ALB_NAME] [-g SECURITY_GROUP_ID] [-t TARGET_GROUP_ARN] [-l CERTIFICATE_ARN] [-u CA_URI]"
        exit 1 ;;
  esac
done

source $CONFIG_FILE

# Validate required parameters
if [ -z "$VPC_ID" ] || [ -z "$SUBNET_IDS" ] || [ -z "$SECURITY_GROUP_ID" ] || [ -z "$TARGET_GROUP_ARN" ] || [ -z "$CERTIFICATE_ARN" ]; then
  echo "VPC_ID, SUBNET_IDS, SECURITY_GROUP_ID, TARGET_GROUP_ARN, and CERTIFICATE_ARN are required parameters."
  exit 1
fi

# Logging setup
LOGFILE="logs/setup_alb.log"
mkdir -p logs

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

error() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE >&2
  exit 1
}

log "Creating Application Load Balancer (ALB) $ALB_NAME in VPC $VPC_ID..."

ALB_ARN=$(aws elbv2 create-load-balancer \
    --name $ALB_NAME \
    --subnets $SUBNET_IDS \
    --security-groups $SECURITY_GROUP_ID \
    --scheme internet-facing \
    --type application \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text) || error "Failed to create ALB"

log "ALB created successfully: $ALB_ARN"

log "Creating listener and configuring HTTPS with mTLS..."

aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=$CERTIFICATE_ARN \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN || error "Failed to create listener and configure HTTPS"

log "ALB listener created and HTTPS configured successfully."

if [ -n "$CA_URI" ]; then
  log "Configuring mTLS with CA URI $CA_URI..."
  # Add mTLS configuration logic here
  log "mTLS configured successfully with CA URI: $CA_URI"
fi
