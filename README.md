# Cloudflare and AWS mTLS Management Scripts

This repository contains a set of Bash scripts designed to manage certificates for Cloudflare's Origin CA, TLS client authentication, and setting up mTLS with AWS Application Load Balancer (ALB). The scripts allow you to create certificates, upload them to Cloudflare, fetch certificate details, delete certificates, and configure AWS resources for mTLS.

## Scripts Overview

### Cloudflare Scripts

1. **`create_ca_and_cert.sh`**
   - Creates a Certificate Authority (CA) and an Application Load Balancer (ALB) certificate. Signs the ALB certificate with the CA and prepares the certificates for upload to Cloudflare.

2. **`upload_cert_to_cf.sh`**
   - Uploads a previously created certificate and its private key to Cloudflare using the Cloudflare API.

3. **`delete_cert_from_cf.sh`**
   - Deletes a certificate from Cloudflare using its certificate ID.

4. **`fetch_certs_from_cf.sh`**
   - Fetches the list of certificates from Cloudflare.

5. **`fetch_tls_client_auth_details.sh`**
   - Fetches the details of TLS client authentication from Cloudflare.

### AWS mTLS Setup Scripts

1. **`setup_s3_trust_store.sh`**
   - Creates an S3 bucket, uploads CA certificates for mTLS, and generates the CA URI for use in the ALB mTLS configuration.

2. **`setup_target_group.sh`**
   - Creates a target group in AWS for the ALB.

3. **`setup_security_groups.sh`**
   - Sets up security groups for the ALB and associated instances.

4. **`setup_alb.sh`**
   - Creates an ALB, associates it with the target group, and configures HTTPS and mTLS.

5. **`validate_acm_certificate.sh`**
   - Requests and validates an ACM certificate using DNS validation via Cloudflare.

## Configuration

All scripts can be configured using:
- A configuration file (`CF_api.conf` or `aws_config.conf`)
- Command-line arguments
- Environment variables

### Configuration File (`CF_api.conf` and `aws_config.conf`)

#### `CF_api.conf` for Cloudflare Scripts:

```bash
ZONEID="your_zone_id_here"
BEARER_TOKEN="your_bearer_token_here"
CF_HOSTNAME="your_hostname_here"
```

#### `aws_config.conf` for AWS Scripts:

```bash
VPC_ID="your_vpc_id"
SUBNET_IDS="subnet-12345678,subnet-87654321"
ALB_NAME="your_alb_name"
SECURITY_GROUP_NAME="your_security_group_name"
TARGET_GROUP_NAME="your_target_group_name"
CERTIFICATE_ARN="your_acm_certificate_arn"
TRUST_STORE_ARN="your_trust_store_arn"
BUCKET_NAME="your_bucket_name"
DOMAIN_NAME="your_domain_name"
CF_HOSTNAME="your_cloudflare_hostname"
```

### Environment Variables

For Cloudflare scripts:

- `ZONEID`: The ID of the Cloudflare zone.
- `BEARER_TOKEN`: The Bearer token for authentication with the Cloudflare API.
- `CF_HOSTNAME`: The hostname for the certificate.

For AWS scripts:

- `VPC_ID`: The ID of the VPC.
- `SUBNET_IDS`: Comma-separated list of subnet IDs where the ALB will be deployed.
- `ALB_NAME`: The name of the ALB.
- `SECURITY_GROUP_NAME`: The name of the security group for the ALB.
- `TARGET_GROUP_NAME`: The name of the target group for the ALB.
- `CERTIFICATE_ARN`: The ARN of the ACM certificate.
- `TRUST_STORE_ARN`: The ARN of the ACM trust store.
- `BUCKET_NAME`: The name of the S3 bucket for the trust store.
- `DOMAIN_NAME`: The domain name for the ACM certificate.
- `CF_HOSTNAME`: The Cloudflare hostname for DNS validation.

### Command-Line Arguments

Each script accepts command-line arguments to override the default or configured values. Use the `-c` option to specify the configuration file, and other options specific to each script.

## Usage

### Cloudflare Scripts

1. **`create_ca_and_cert.sh`**

   - Creates a CA and an ALB certificate, signs the ALB certificate, and optionally links it to Cloudflare client certificates.

   #### Command-Line Usage

   ```bash
   ./create_ca_and_cert.sh [-c CONFIG_FILE] [-h CF_HOSTNAME] [-s CA_SUBJECT] [-a ALB_CERT_DAYS] [-d CA_CERT_DAYS]
   ```

   - `-c CONFIG_FILE`: Path to the configuration file (default: `CF_api.conf`).
   - `-h CF_HOSTNAME`: Hostname for the ALB certificate.
   - `-s CA_SUBJECT`: Subject for the CA certificate.
   - `-a ALB_CERT_DAYS`: Validity period of the ALB certificate in days.
   - `-d CA_CERT_DAYS`: Validity period of the CA certificate in days.

   #### Example

   ```bash
   ./create_ca_and_cert.sh -h "example.com" -s "/CN=My CA" -a 365 -d 1825
   ```

2. **`upload_cert_to_cf.sh`**

   - Uploads a certificate and its private key to Cloudflare using the API.

   #### Command-Line Usage

   ```bash
   ./upload_cert_to_cf.sh [-c CONFIG_FILE] [-z ZONEID] [-t BEARER_TOKEN] [CERT_ID]
   ```

   - `-c CONFIG_FILE`: Path to the configuration file (default: `CF_api.conf`).
   - `-z ZONEID`: Cloudflare zone ID.
   - `-t BEARER_TOKEN`: Bearer token for Cloudflare API.
   - `CERT_ID`: Optional certificate ID to use for upload.

   #### Example

   ```bash
   ./upload_cert_to_cf.sh -z "your_zone_id" -t "your_bearer_token" "your_cert_id"
   ```

3. **`delete_cert_from_cf.sh`**

   - Deletes a certificate from Cloudflare by its certificate ID.

   #### Command-Line Usage

   ```bash
   ./delete_cert_from_cf.sh [-c CONFIG_FILE] [-z ZONEID] [-t BEARER_TOKEN] [CERT_ID]
   ```

   - `-c CONFIG_FILE`: Path to the configuration file (default: `CF_api.conf`).
   - `-z ZONEID`: Cloudflare zone ID.
   - `-t BEARER_TOKEN`: Bearer token for Cloudflare API.
   - `CERT_ID`: The certificate ID to delete.

   #### Example

   ```bash
   ./delete_cert_from_cf.sh -z "your_zone_id" -t "your_bearer_token" "your_cert_id"
   ```

4. **`fetch_certs_from_cf.sh`**

   - Fetches and lists the certificates from Cloudflare.

   #### Command-Line Usage

   ```bash
   ./fetch_certs_from_cf.sh [-c CONFIG_FILE] [-z ZONEID] [-t BEARER_TOKEN]
   ```

   - `-c CONFIG_FILE`: Path to the configuration file (default: `CF_api.conf`).
   - `-z ZONEID`: Cloudflare zone ID.
   - `-t BEARER_TOKEN`: Bearer token for Cloudflare API.

   #### Example

   ```bash
   ./fetch_certs_from_cf.sh -z "your_zone_id" -t "your_bearer_token"
   ```

5. **`fetch_tls_client_auth_details.sh`**

   - Fetches the details of TLS client authentication from Cloudflare.

   #### Command-Line Usage

   ```bash
   ./fetch_tls_client_auth_details.sh [-c CONFIG_FILE] [-z ZONEID] [-t BEARER_TOKEN]
   ```

   - `-c CONFIG_FILE`: Path to the configuration file (default: `CF_api.conf`).
   - `-z ZONEID`: Cloudflare zone ID.
   - `-t BEARER_TOKEN`: Bearer token for Cloudflare API.

   #### Example

   ```bash
   ./fetch_tls_client_auth_details.sh -z "your_zone_id" -t "your_bearer_token"
   ```

### AWS mTLS Setup Scripts

1. **`setup_s3_trust_store.sh`**

   - Creates an S3 bucket, uploads CA certificates for mTLS, and generates the CA URI for use in the ALB mTLS configuration.

   #### Command-Line Usage

   ```bash
   ./setup_s3_trust_store.sh [-c CONFIG_FILE] [-b BUCKET_NAME] [-d DIRECTORY_PATH]
   ```

   - `-c CONFIG_FILE`: Path to the configuration file (default: `aws_config.conf`).
   - `-b BUCKET_NAME`: Name of the S3 bucket to create.
   - `-d DIRECTORY_PATH`: Directory containing CA certificates to upload.

   #### Example

   ```bash
   ./setup_s3_trust_store.sh -b "my-mtls-trust-store" -d "./ca-certs"
   ```

2. **`setup_target_group.sh`**

   - Creates a target group in AWS for the ALB.

   #### Command-Line Usage

   ```bash
   ./setup_target_group.sh [-c CONFIG_FILE] [-n TARGET_GROUP_NAME] [-v

 VPC_ID] [-p PROTOCOL] [-h PORT] [-t TARGET_TYPE]
   ```

   - `-c CONFIG_FILE`: Path to the configuration file (default: `aws_config.conf`).
   - `-n TARGET_GROUP_NAME`: Name of the target group.
   - `-v VPC_ID`: VPC ID where the target group will be created.
   - `-p PROTOCOL`: Protocol for the target group (default: HTTP).
   - `-h PORT`: Port for the target group (default: 80).
   - `-t TARGET_TYPE`: Target type (default: instance).

   #### Example

   ```bash
   ./setup_target_group.sh -n "MyTargetGroup" -v "vpc-12345678" -p "HTTP" -h 80 -t "instance"
   ```

3. **`setup_security_groups.sh`**

   - Sets up security groups for the ALB and associated instances.

   #### Command-Line Usage

   ```bash
   ./setup_security_groups.sh [-c CONFIG_FILE] [-n SECURITY_GROUP_NAME] [-v VPC_ID]
   ```

   - `-c CONFIG_FILE`: Path to the configuration file (default: `aws_config.conf`).
   - `-n SECURITY_GROUP_NAME`: Name of the security group.
   - `-v VPC_ID`: VPC ID where the security group will be created.

   #### Example

   ```bash
   ./setup_security_groups.sh -n "MySecurityGroup" -v "vpc-12345678"
   ```

4. **`setup_alb.sh`**

   - Creates an ALB, associates it with the target group, and configures HTTPS and mTLS.

   #### Command-Line Usage

   ```bash
   ./setup_alb.sh [-c CONFIG_FILE] [-v VPC_ID] [-s SUBNET_IDS] [-n ALB_NAME] [-g SECURITY_GROUP_ID] [-t TARGET_GROUP_ARN] [-l CERTIFICATE_ARN] [-u CA_URI]
   ```

   - `-c CONFIG_FILE`: Path to the configuration file (default: `aws_config.conf`).
   - `-v VPC_ID`: VPC ID where the ALB will be created.
   - `-s SUBNET_IDS`: Comma-separated list of subnet IDs for the ALB.
   - `-n ALB_NAME`: Name of the ALB.
   - `-g SECURITY_GROUP_ID`: Security group ID for the ALB.
   - `-t TARGET_GROUP_ARN`: ARN of the target group.
   - `-l CERTIFICATE_ARN`: ARN of the ACM certificate.
   - `-u CA_URI`: URI of the S3 bucket with CA certificates for mTLS.

   #### Example

   ```bash
   ./setup_alb.sh -v "vpc-12345678" -s "subnet-12345678,subnet-87654321" -n "MyALB" -g "sg-12345678" -t "arn:aws:elasticloadbalancing:region:account-id:targetgroup/name/id" -l "arn:aws:acm:region:account-id:certificate/id" -u "s3://my-mtls-trust-store/"
   ```

5. **`validate_acm_certificate.sh`**

   - Requests and validates an ACM certificate using DNS validation via Cloudflare.

   #### Command-Line Usage

   ```bash
   ./validate_acm_certificate.sh [-c CONFIG_FILE] [-d DOMAIN_NAME] [-h CF_HOSTNAME] [-z ZONEID] [-t BEARER_TOKEN]
   ```

   - `-c CONFIG_FILE`: Path to the configuration file (default: `aws_config.conf`).
   - `-d DOMAIN_NAME`: Domain name for the ACM certificate.
   - `-h CF_HOSTNAME`: Cloudflare hostname for DNS validation.
   - `-z ZONEID`: Cloudflare zone ID.
   - `-t BEARER_TOKEN`: Cloudflare API bearer token.

   #### Example

   ```bash
   ./validate_acm_certificate.sh -d "example.com" -h "example.com" -z "your_zone_id" -t "your_bearer_token"
   ```

## Logging

Each script generates logs in two files:
- `log.txt`: Contains informational and error messages.
- `debug_log.txt`: Contains detailed debug messages.

## Error Handling

The scripts are designed to handle errors gracefully by:
- Logging errors to `log.txt`.
- Exiting with a non-zero status on critical errors.
- Providing meaningful error messages for troubleshooting.

## Security

Sensitive information such as Bearer tokens and private keys are handled securely. Ensure that these details are protected and not exposed in logs or configuration files.

## Automated Testing

To automate the testing of these scripts, we can use a master script that sequentially executes each script and verifies its output. Here’s a sample master test script:

### Automated Test Script: `run_tests.sh`

```bash
#!/bin/bash

# Define log files
LOGFILE="test_log.txt"
DEBUG_LOGFILE="test_debug_log.txt"

# Function to log info messages
log_info() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

# Function to log error messages
log_error() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE
}

# Test variables
CONFIG_FILE="CF_api.conf"
AWS_CONFIG_FILE="aws_config.conf"
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
```

## How to Run Automated Tests

1. Make sure you have all the scripts and configuration files (`CF_api.conf` and `aws_config.conf`) in the same directory.
2. Ensure AWS CLI and jq are installed and configured on your system.
3. Execute the master test script:

```bash
chmod +x run_tests.sh
./run_tests.sh
```
