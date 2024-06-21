#!/bin/bash

# Define log files
LOGFILE="trust_store_setup_log.txt"
DEBUG_LOGFILE="trust_store_setup_debug_log.txt"

# Default configuration values
CONFIG_FILE="aws_config.conf"
TRUST_STORE_NAME=""
CA_CERTIFICATE_ARN=""

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
    echo "Usage: $0 [-c CONFIG_FILE] [-n TRUST_STORE_NAME] [-a CA_CERTIFICATE_ARN]"
    exit 1
}

# Parse command-line arguments
while getopts "c:n:a:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        n) TRUST_STORE_NAME="$OPTARG" ;;
        a) CA_CERTIFICATE_ARN="$OPTARG" ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

# Load configuration from file if it exists
if [ -f $CONFIG_FILE ]; then
    . $CONFIG_FILE
    log_info "Loaded configuration f
