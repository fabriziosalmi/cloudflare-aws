#!/bin/bash

# Define log files
LOGFILE="logs/test_log.txt"
DEBUG_LOGFILE="logs/test_debug_log.txt"

# Function to log info messages
log_info() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

# Function to log error messages
log_error() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE
}

# Test variables
CONFIG_FILE="config/CF_api.conf"
AWS_CONFIG_FILE="config/aws_config.conf"
BUCKET_NAME="test-mtls-trust-store"
CA_CERTS_DIR="./ca-certs"
DOMAIN_NAME="example.com"
CERT_ID="test-cert-id"

# Run each script and check if it succeeds
run_script() {
    local script=$1
    local args=$2

    log_info "Running script: $script with args: $args"
    ./$script $args
    if [ $? -eq 0 ]; then
        log_info "Script $script completed successfully."
    else
        log_error "Script $script failed."
        exit 1
    fi
}

# Step 1: Create CA and certificates
run_script "create_ca_and_cert.sh" "-c $CONFIG_FILE -h $DOMAIN_NAME"

# Step 2: Upload certificate to Cloudflare
run_script "upload_cert_to_cf.sh" "-c $CONFIG_FILE -z \$ZONEID -t \$BEARER_TOKEN $CERT_ID"

# Step 3: Fetch certificates from Cloudflare
run_script "fetch_certs_from_cf.sh" "-c $CONFIG_FILE -z \$ZONEID -t \$BEARER_TOKEN"

# Step 4: Fetch TLS client auth details
run_script "fetch_tls_client_auth_details.sh" "-c $CONFIG_FILE -z \$ZONEID -t \$BEARER_TOKEN"

# Step 5: Delete certificate from Cloudflare
run_script "delete_cert_from_cf.sh" "-c $CONFIG_FILE -z \$ZONEID -t \$BEARER_TOKEN $CERT_ID"

# Step 6: Set up S3 trust store
run_script "setup_s3_trust_store.sh" "-c $AWS_CONFIG_FILE -b $BUCKET_NAME -d $CA_CERTS_DIR"

# Step 7: Set up target group
run_script "setup_target_group.sh" "-c $AWS_CONFIG_FILE -n \$TARGET_GROUP_NAME -v \$VPC_ID"

# Step 8: Set up security groups
run_script "setup_security_groups.sh" "-c $AWS_CONFIG_FILE -n \$SECURITY_GROUP_NAME -v \$VPC_ID"

# Step 9: Create ALB and configure mTLS
run_script "setup_alb.sh" "-c $AWS_CONFIG_FILE -v \$VPC_ID -s \$SUBNET_IDS -n \$ALB_NAME -g \$SECURITY_GROUP_ID -t \$TARGET_GROUP_ARN -l \$CERTIFICATE_ARN -u s3://$BUCKET_NAME/"

# Step 10: Validate ACM certificate via Cloudflare
run_script "validate_acm_certificate.sh" "-c $AWS_CONFIG_FILE -d \$DOMAIN_NAME -h \$CF_HOSTNAME -z \$ZONEID -t \$BEARER_TOKEN"

log_info "All tests completed successfully."
