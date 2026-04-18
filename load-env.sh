#!/bin/bash

# =============================================================================
# load-env.sh - Load configuration and secrets
# =============================================================================
# Usage:
#   source ./load-env.sh dev
#   docker compose up
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

ENVIRONMENT="${1:-dev}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# OCI Config
OCI_VAULT_ID="${OCI_VAULT_ID:-ocid1.vault.oc1.eu-paris-1.h5u5r66aaaeyw.abrwiljr4fkinvkag3fxlldwamaodr6abfnmzzc2ic3ctp5pze6m6n6ambda}"
OCI_REGION="${OCI_REGION:-eu-paris-1}"
OCI_COMPARTMENT_ID="${OCI_COMPARTMENT_ID:-ocid1.tenancy.oc1..aaaaaaaasupkx3tssc6m3pshvxpqszf4yaoc4m2b7vts7gwulld2yh7acifq}"

# =============================================================================
# Load Config from .env file
# =============================================================================

load_config() {
    local env_file=".env.${ENVIRONMENT}"
    
    if [[ ! -f "$env_file" ]]; then
        log_error "Config file not found: $env_file"
        exit 1
    fi
    
    log_info "Loading config from $env_file..."
    
    set -a
    source "$env_file"
    set +a
    
    log_info "Config loaded: ENVIRONMENT=$ENVIRONMENT BACKEND_TAG=$BACKEND_TAG FRONT_TAG=$FRONT_TAG"
}

# =============================================================================
# Load Secrets from OCI Vault, fallback file, or local postgres
# =============================================================================

declare -A SECRET_NAMES=(
    ["DB_HOST"]="DB_HOST"
    ["DB_PORT"]="DB_PORT"
    ["DB_NAME"]="DB_NAME"
    ["DB_USERNAME"]="DB_USERNAME"
    ["DB_PASSWORD"]="DB_PASSWORD"
)

load_local_secrets() {
    local secrets_file=".env.secrets.${ENVIRONMENT}"
    
    if [[ -f "$secrets_file" ]]; then
        log_info "Loading secrets from $secrets_file..."
        
        set -a
        source "$secrets_file"
        set +a
        
        for var_name in "${!SECRET_NAMES[@]}"; do
            local value="${!var_name}"
            if [[ -n "$value" ]]; then
                export "$var_name=$value"
                log_info "Loaded: $var_name"
            fi
        done
        
        log_info "Local secrets loaded from $secrets_file"
    else
        log_error "Secrets file not found: $secrets_file"
        exit 1
    fi
}

load_from_oci() {
    if ! command -v oci &> /dev/null; then
        log_warn "OCI CLI not found"
        return 1
    fi
    
    log_info "Loading secrets from OCI Vault..."
    
    for var_name in "${!SECRET_NAMES[@]}"; do
        local secret_name="${SECRET_NAMES[$var_name]}"
        
        local secret_ocid
        secret_ocid=$(oci vault secret list \
            --compartment-id "$OCI_COMPARTMENT_ID" \
            --vault-id "$OCI_VAULT_ID" \
            --name "$secret_name" \
            --query "data[0].id" \
            --raw-output 2>/dev/null) || true
        
        if [[ -n "$secret_ocid" && "$secret_ocid" != "null" ]]; then
            local secret_value
            secret_value=$(oci secrets secret-bundle get \
                --secret-id "$secret_ocid" \
                --query 'data."secret-bundle-content".content' \
                --raw-output 2>/dev/null)
            
            if [[ -n "$secret_value" ]]; then
                export "$var_name=$(echo "$secret_value" | base64 -d)"
                log_info "Loaded from OCI: $var_name"
            fi
        else
            log_warn "Secret not found in OCI: $secret_name"
        fi
    done
    
    local loaded_count=0
    for var_name in "${!SECRET_NAMES[@]}"; do
        if [[ -n "${!var_name:-}" ]]; then
            ((loaded_count++))
        fi
    done
    
    if [[ $loaded_count -eq 0 ]]; then
        return 1
    fi
}

load_from_secrets_file() {
    local secrets_file=".env.secrets.${ENVIRONMENT}"
    
    if [[ -f "$secrets_file" ]]; then
        log_info "Loading secrets from $secrets_file..."
        
        set -a
        source "$secrets_file"
        set +a
        
        for var_name in "${!SECRET_NAMES[@]}"; do
            local value="${!var_name}"
            if [[ -n "$value" ]]; then
                export "$var_name=$value"
                log_info "Loaded from file: $var_name"
            fi
        done
        
        log_info "Secrets loaded from $secrets_file"
    else
        log_error "No OCI CLI and no $secrets_file found!"
        echo "  Create $secrets_file with your secrets OR configure OCI CLI"
        exit 1
    fi
}

# =============================================================================
# SSL Certificates
# =============================================================================

declare -A SSL_SECRET_NAMES=(
    ["SSL_CERT"]="SSL_CERT"
    ["SSL_KEY"]="SSL_KEY"
)

load_local_ssl() {
    local secrets_file=".env.secrets.${ENVIRONMENT}"
    local cert_dir="certs"
    
    if [[ -f "$secrets_file" ]]; then
        set -a
        source "$secrets_file"
        set +a
        
        mkdir -p "$cert_dir"
        
        if [[ -n "${SSL_CERT:-}" ]]; then
            echo "$SSL_CERT" > "$cert_dir/cert.pem"
            log_info "SSL certificate written to $cert_dir/cert.pem"
        fi
        
        if [[ -n "${SSL_KEY:-}" ]]; then
            echo "$SSL_KEY" > "$cert_dir/key.pem"
            log_info "SSL key written to $cert_dir/key.pem"
        fi
        
        if [[ -n "${SSL_CERT:-}" || -n "${SSL_KEY:-}" ]]; then
            log_info "Local SSL certificates loaded from $secrets_file"
        fi
    fi
}

load_oci_ssl() {
    local cert_dir="certs"
    mkdir -p "$cert_dir"
    
    for var_name in "${!SSL_SECRET_NAMES[@]}"; do
        local secret_name="${SSL_SECRET_NAMES[$var_name]}"
        
        local secret_ocid
        secret_ocid=$(oci vault secret list \
            --compartment-id "$OCI_COMPARTMENT_ID" \
            --vault-id "$OCI_VAULT_ID" \
            --name "$secret_name" \
            --query "data[0].id" \
            --raw-output 2>/dev/null) || true
        
        if [[ -n "$secret_ocid" && "$secret_ocid" != "null" ]]; then
            local secret_value
            secret_value=$(oci secrets secret-bundle get \
                --secret-id "$secret_ocid" \
                --query 'data."secret-bundle-content".content' \
                --raw-output 2>/dev/null)
            
            if [[ -n "$secret_value" ]]; then
                local decoded
                decoded=$(echo "$secret_value" | base64 -d)
                
                if [[ "$var_name" == "SSL_CERT" ]]; then
                    echo "$decoded" > "$cert_dir/cert.pem"
                else
                    echo "$decoded" > "$cert_dir/key.pem"
                fi
                log_info "SSL $var_name loaded from OCI"
            fi
        else
            log_warn "SSL secret not found in OCI: $secret_name"
        fi
    done
}

# =============================================================================
# Main
# =============================================================================

main() {
    log_info "=== Loading environment: $ENVIRONMENT ==="
    
    load_config
    
    if [[ "$ENVIRONMENT" == "local" ]]; then
        load_local_secrets
        load_local_ssl
    else
        load_from_oci || load_from_secrets_file
        load_oci_ssl
    fi
    
    export ENVIRONMENT BACKEND_TAG FRONT_TAG DB_HOST DB_PORT DB_NAME DB_USERNAME DB_PASSWORD
    
    log_info "Environment loaded successfully!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
else
    load_config
    if [[ "$ENVIRONMENT" == "local" ]]; then
        load_local_secrets
        load_local_ssl
    else
        load_from_oci || load_from_secrets_file
        load_oci_ssl
    fi
fi