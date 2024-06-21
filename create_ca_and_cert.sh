#!/bin/bash

# Define log files
LOGFILE="log.txt"
DEBUG_LOGFILE="debug_log.txt"

# Default configuration values
CONFIG_FILE="CF_api.conf"
CA_SUBJECT="/CN=mTLS Test CA"
ALB_CERT_DAYS=730
CA_CERT_DAYS=356

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
    echo "Usage: $0 [-c CONFIG_FILE] [-h CF_HOSTNAME] [-s CA_SUBJECT] [-a ALB_CERT_DAYS] [-d CA_CERT_DAYS]"
    exit 1
}

# Parse command-line arguments
while getopts "c:h:s:a:d:" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        h) CF_HOSTNAME="$OPTARG" ;;
        s) CA_SUBJECT="$OPTARG" ;;
        a) ALB_CERT_DAYS="$OPTARG" ;;
        d) CA_CERT_DAYS="$OPTARG" ;;
        *) usage ;;
    esac
done

# Load configuration from file if it exists
if [ -f $CONFIG_FILE ]; then
    . $CONFIG_FILE
    log_info "Loaded configuration from $CONFIG_FILE."
else
    log_info "Configuration file $CONFIG_FILE not found. Using defaults and environment variables."
fi

# Check if required variables are set, either by command-line arguments, environment variables, or config file
CF_HOSTNAME=${CF_HOSTNAME:-${CF_HOSTNAME_ENV}}
CF_HOSTNAME=${CF_HOSTNAME:-$(printenv CF_HOSTNAME)}
CA_SUBJECT=${CA_SUBJECT:-$(printenv CA_SUBJECT)}
ALB_CERT_DAYS=${ALB_CERT_DAYS:-$(printenv ALB_CERT_DAYS)}
CA_CERT_DAYS=${CA_CERT_DAYS:-$(printenv CA_CERT_DAYS)}

# Ensure CF_HOSTNAME is set
if [ -z "$CF_HOSTNAME" ]; then
    log_error "CF_HOSTNAME is not set. Use -h to provide it or set it in the environment/config file."
    usage
fi

# Function to create a certificate authority (CA)
create_ca() {
    log_info "Creating Certificate Authority (CA)..."
    openssl req -x509 -sha256 -newkey rsa:4096 -keyout rootca.key -out rootca.crt -days $CA_CERT_DAYS -nodes -subj "$CA_SUBJECT" 2>>$DEBUG_LOGFILE
    if [ $? -eq 0 ]; then
        log_info "CA created successfully."
        chmod 600 rootca.key
        log_debug "CA private key permissions set to 600."
    else
        log_error "Failed to create CA."
        exit 1
    fi
}

# Function to create an ALB certificate
create_alb_cert() {
    log_info "Creating ALB certificate..."
    openssl req -new -nodes -out cert.csr -newkey rsa:4096 -keyout cert.key -subj "/CN=${CF_HOSTNAME}" 2>>$DEBUG_LOGFILE
    if [ $? -eq 0 ]; then
        log_info "ALB certificate created successfully."
        chmod 600 cert.key
        log_debug "ALB private key permissions set to 600."
    else
        log_error "Failed to create ALB certificate."
        exit 1
    fi
}

# Function to sign an ALB certificate
sign_alb_cert() {
    log_info "Signing ALB certificate with CA..."
    echo "basicConstraints=CA:FALSE" > ./cert.v3.ext
    openssl x509 -req -in cert.csr -CA rootca.crt -CAkey rootca.key -CAcreateserial -out cert.crt -days $ALB_CERT_DAYS -sha256 -extfile ./cert.v3.ext 2>>$DEBUG_LOGFILE
    if [ $? -eq 0 ]; then
        log_info "ALB certificate signed successfully."
    else
        log_error "Failed to sign ALB certificate."
        exit 1
    fi
}

# Function to create symlinks for certificates
create_symlinks() {
    log_info "Creating symlinks for CloudFlare certificate..."
    ln -f -s cert.crt client.crt 2>>$DEBUG_LOGFILE
    ln -f -s cert.key client.key 2>>$DEBUG_LOGFILE
    if [ $? -eq 0 ]; then
        log_info "Symlinks created successfully."
    else
        log_error "Failed to create symlinks."
        exit 1
    fi
}

# Function to save the serial number of the certificate
save_serial() {
    log_info "Saving SERIAL of cert.crt in cert.serial..."
    SERIAL="0x$(openssl x509 -in cert.crt -noout -serial | cut -d'=' -f2)"
    if [ $? -eq 0 ]; then
        echo -n "$SERIAL" | gawk -nM '$_+=_' > cert.serial
        if [ $? -eq 0 ]; then
            log_info "Serial number saved successfully in cert.serial."
        else
            log_error "Failed to save serial number in cert.serial."
            exit 1
        fi
    else
        log_error "Failed to retrieve serial number from cert.crt."
        exit 1
    fi
}

# Trap to catch errors and clean up if script exits unexpectedly
trap 'log_error "Script terminated unexpectedly."; exit 1' ERR

# Execute the steps
create_ca
create_alb_cert
sign_alb_cert
create_symlinks
save_serial

log_info "Script completed successfully."
