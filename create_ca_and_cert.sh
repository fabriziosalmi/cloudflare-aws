#!/bin/bash

# Load configuration
CONFIG_FILE="config/CF_api.conf"
CA_CERT_DAYS=1825
ALB_CERT_DAYS=365
CA_SUBJECT="/CN=My CA"
CF_HOSTNAME=""

while getopts "c:h:s:a:d:" opt; do
  case ${opt} in
    c) CONFIG_FILE=$OPTARG ;;
    h) CF_HOSTNAME=$OPTARG ;;
    s) CA_SUBJECT=$OPTARG ;;
    a) ALB_CERT_DAYS=$OPTARG ;;
    d) CA_CERT_DAYS=$OPTARG ;;
    \?) echo "Usage: $0 [-c CONFIG_FILE] [-h CF_HOSTNAME] [-s CA_SUBJECT] [-a ALB_CERT_DAYS] [-d CA_CERT_DAYS]"
        exit 1 ;;
  esac
done

source $CONFIG_FILE

# Logging setup
LOGFILE="logs/create_ca_and_cert.log"
mkdir -p logs

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOGFILE
}

error() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOGFILE >&2
  exit 1
}

log "Creating Certificate Authority (CA)..."
openssl req -new -x509 -days $CA_CERT_DAYS -keyout ca-key.pem -out ca-cert.pem -subj "$CA_SUBJECT" || error "Failed to create CA certificate"

log "Generating ALB private key..."
openssl genrsa -out alb-key.pem 2048 || error "Failed to generate ALB private key"

log "Creating ALB certificate signing request (CSR)..."
openssl req -new -key alb-key.pem -out alb-csr.pem -subj "/CN=$CF_HOSTNAME" || error "Failed to create ALB CSR"

log "Signing ALB certificate with CA..."
openssl x509 -req -days $ALB_CERT_DAYS -in alb-csr.pem -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out alb-cert.pem || error "Failed to sign ALB certificate"

log "Certificates created successfully. Files: ca-cert.pem, ca-key.pem, alb-cert.pem, alb-key.pem"
