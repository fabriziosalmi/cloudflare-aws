# Cloudflare and AWS mTLS Management Scripts

This repository contains a set of Bash scripts designed to manage certificates for Cloudflare's Origin CA, TLS client authentication, and setting up mTLS with AWS Application Load Balancer (ALB).

## Scripts Overview

### Cloudflare Scripts

- **create_ca_and_cert.sh**
  - Creates a Certificate Authority (CA) and an Application Load Balancer (ALB) certificate. Signs the ALB certificate with the CA and prepares the certificates for upload to Cloudflare.

- **upload_cert_to_cf.sh**
  - Uploads a previously created certificate and its private key to Cloudflare using the Cloudflare API.

- **delete_cert_from_cf.sh**
  - Deletes a certificate from Cloudflare using its certificate ID.

- **fetch_certs_from_cf.sh**
  - Fetches the list of certificates from Cloudflare.

- **fetch_tls_client_auth_details.sh**
  - Fetches the details of TLS client authentication from Cloudflare.

### AWS mTLS Setup Scripts

- **setup_s3_trust_store.sh**
  - Creates an S3 bucket, uploads CA certificates for mTLS, and generates the CA URI for use in the ALB mTLS configuration.

- **setup_target_group.sh**
  - Creates a target group in AWS for the ALB.

- **setup_security_groups.sh**
  - Sets up security groups for the ALB and associated instances.

- **setup_alb.sh**
  - Creates an ALB, associates it with the target group, and configures HTTPS and mTLS.

- **validate_acm_certificate.sh**
  - Requests and validates an ACM certificate using DNS validation via Cloudflare.

## Configuration

All scripts can be configured using:
- A configuration file (`CF_api.conf` or `aws_config.conf`)
- Command-line arguments
- Environment variables

### Configuration Files

- `CF_api.conf` for Cloudflare scripts
- `aws_config.conf` for AWS scripts
