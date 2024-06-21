#!/bin/bash

# Load configuration
CONFIG_FILE="config/aws_config.conf"
CA_CERTS_DIR="."
BUCKET_NAME=""

while getopts "c:b:d:" opt; do
  case ${opt} in
    c) CONFIG_FILE=$OPTARG ;;
    b) BUCKET_NAME=$OPTARG ;;
    d) CA_CERTS_DIR=$OPTARG ;;
    \?) echo "Usage: $0 [-c CONFIG_FILE] [-b BUCKET_NAME] [-d DIRECTORY_PATH]"
        exit 1 ;;
  esac
done

source $CONFIG_FILE

# Validate required parameters
if [ -z "$BUCKET_NAME" ]; then
  echo "BUCKET_NAME is a required parameter."
  exit 1
fi

# Logging setup
LOGFILE="logs/setup_s3_trust_store.log"
mkdir -p logs

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

error() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE >&2
  exit 1
}

log "Creating S3 bucket $BUCKET_NAME..."
aws s3 mb s3://$BUCKET_NAME || error "Failed to create S3 bucket $BUCKET_NAME"

log "Uploading CA certificates to S3 bucket..."
aws s3 cp $CA_CERTS_DIR s3://$BUCKET_NAME/ --recursive || error "Failed to upload CA certificates to S3 bucket $BUCKET_NAME"

log "CA certificates uploaded successfully. URI: s3://$BUCKET_NAME/"
