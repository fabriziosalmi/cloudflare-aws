# Cloudflare Certificate Management Scripts

This repository contains a set of Bash scripts designed to manage certificates for Cloudflare's Origin CA and TLS client authentication. The scripts allow you to create certificates, upload them to Cloudflare, fetch certificate details, and delete certificates as needed.

## Scripts Overview

### 1. `create_ca_and_cert.sh`

This script creates a Certificate Authority (CA) and an Application Load Balancer (ALB) certificate. It signs the ALB certificate with the CA, and prepares the certificates for upload to Cloudflare.

### 2. `upload_cert_to_cf.sh`

This script uploads a previously created certificate and its private key to Cloudflare using the Cloudflare API.

### 3. `delete_cert_from_cf.sh`

This script deletes a certificate from Cloudflare using its certificate ID.

### 4. `fetch_certs_from_cf.sh`

This script fetches the list of certificates from Cloudflare.

### 5. `fetch_tls_client_auth_details.sh`

This script fetches the details of TLS client authentication from Cloudflare.

## Configuration

All scripts can be configured using:
- A configuration file (`CF_api.conf`)
- Command-line arguments
- Environment variables

### Configuration File (`CF_api.conf`)

The configuration file should define the following variables:

```bash
ZONEID="your_zone_id_here"
BEARER_TOKEN="your_bearer_token_here"
CF_HOSTNAME="your_hostname_here"
```

### Environment Variables

You can also set the following environment variables:

- `ZONEID`: The ID of the Cloudflare zone.
- `BEARER_TOKEN`: The Bearer token for authentication with the Cloudflare API.
- `CF_HOSTNAME`: The hostname for the certificate.

### Command-Line Arguments

Each script accepts command-line arguments to override the default or configured values. Use the `-c` option to specify the configuration file, `-z` for the zone ID, `-t` for the bearer token, and `-h` for the hostname.

## Usage

### 1. `create_ca_and_cert.sh`

This script creates a CA and an ALB certificate, signs the ALB certificate, and optionally links it to Cloudflare client certificates.

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

### 2. `upload_cert_to_cf.sh`

This script uploads a certificate and its private key to Cloudflare using the API.

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

### 3. `delete_cert_from_cf.sh`

This script deletes a certificate from Cloudflare by its certificate ID.

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

### 4. `fetch_certs_from_cf.sh`

This script fetches and lists the certificates from Cloudflare.

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

### 5. `fetch_tls_client_auth_details.sh`

This script fetches the details of TLS client authentication from Cloudflare.

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


