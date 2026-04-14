#!/bin/bash

# =============================================================================
# dump-supabase.sh - Dump Supabase database to SQL file
# =============================================================================
# Usage:
#   docker run --rm -it -v "%cd%/backups:/backups" -w /app -e ENV=dev ossemaabd95/stackvault:backend-dev bash dump-supabase.sh dev
#   docker run --rm -it -v "%cd%/backups:/backups" -w /app -e ENV=dev -e OCI_UPLOAD=true ossemaabd95/stackvault:backend-dev bash dump-supabase.sh dev --oci
# =============================================================================

set -euo pipefail

ENVIRONMENT="${1:-dev}"
UPLOAD_TO_OCI="${OCI_UPLOAD:-false}"

if [[ "${2:-}" == "--oci" ]]; then
    UPLOAD_TO_OCI=true
fi

DUMP_DIR="${DUMP_DIR:-./backups}"
RETENTION=3

OCI_REGION="${OCI_REGION:-eu-paris-1}"
OCI_COMPARTMENT_ID="${OCI_COMPARTMENT_ID:-ocid1.tenancy.oc1..aaaaaaaasupkx3tssc6m3pshvxpqszf4yaoc4m2b7vts7gwulld2yh7acifq}"
OCI_BUCKET_NAME="${OCI_BUCKET_NAME:-portfolio-backups}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

load_env() {
    local config_file=".env.${ENVIRONMENT}"
    local secrets_file=".env.secrets.${ENVIRONMENT}"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        exit 1
    fi
    
    if [[ ! -f "$secrets_file" ]]; then
        log_error "Secrets file not found: $secrets_file"
        exit 1
    fi
    
    set -a
    source "$config_file"
    source "$secrets_file"
    set +a
    
    if [[ -z "${DB_HOST:-}" || -z "${DB_USERNAME:-}" || -z "${DB_NAME:-}" ]]; then
        log_error "Database credentials not loaded"
        exit 1
    fi
    
    log_info "DB: $DB_HOST:$DB_PORT/$DB_NAME"
}

ensure_dump_dir() {
    mkdir -p "$DUMP_DIR"
}

ensure_oci_bucket() {
    if ! command -v oci &> /dev/null; then
        log_warn "OCI CLI not found, skipping OCI upload"
        UPLOAD_TO_OCI=false
        return 1
    fi
    
    log_info "Checking OCI bucket..."
    
    local bucket_exists
    bucket_exists=$(oci os bucket get \
        --compartment-id "$OCI_COMPARTMENT_ID" \
        --bucket-name "$OCI_BUCKET_NAME" \
        --query "data.name" \
        --raw-output 2>/dev/null) || true
    
    if [[ -z "$bucket_exists" || "$bucket_exists" == "null" ]]; then
        log_info "Creating bucket: $OCI_BUCKET_NAME"
        oci os bucket create \
            --compartment-id "$OCI_COMPARTMENT_ID" \
            --bucket-name "$OCI_BUCKET_NAME" \
            --storage-tier "Standard" \
            --public-access-type "NoPublicAccess" || true
    else
        log_info "Bucket already exists: $OCI_BUCKET_NAME"
    fi
}

dump_database() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    local dump_filename="${ENVIRONMENT}_supabase_dump_${timestamp}.sql.gz"
    local dump_path="${DUMP_DIR}/${dump_filename}"
    
    log_info "Dumping database..."
    log_info "Output: $dump_path"
    
    PGPASSWORD="$DB_PASSWORD" pg_dump \
        -h "$DB_HOST" \
        -p "${DB_PORT:-5432}" \
        -U "$DB_USERNAME" \
        -d "$DB_NAME" \
        --clean \
        --if-exists \
        --create \
        --inserts \
        --no-privileges \
        --no-owner \
        2>&1 | gzip > "$dump_path"
    
    if [[ ! -s "$dump_path" ]]; then
        log_error "Dump failed or is empty"
        log_error "Output: $(ls -la "$dump_path" 2>&1 || echo 'not found')"
        exit 1
    fi
    
    local size
    size=$(du -h "$dump_path" | cut -f1)
    log_info "Dump created: $size"
    
    echo "$dump_path"
}

cleanup_local_dumps() {
    local dump_count
    dump_count=$(ls -1 "$DUMP_DIR"/${ENVIRONMENT}_supabase_dump_*.sql.gz 2>/dev/null | wc -l)
    
    if [[ $dump_count -le $RETENTION ]]; then
        return 0
    fi
    
    log_info "Cleaning up old local dumps (keeping $RETENTION)..."
    
    ls -1t "$DUMP_DIR"/${ENVIRONMENT}_supabase_dump_*.sql.gz 2>/dev/null | \
        tail -n +$((RETENTION + 1)) | \
        xargs -r rm
    
    log_info "Cleanup complete"
}

upload_to_oci() {
    local dump_path="$1"
    local dump_filename
    dump_filename=$(basename "$dump_path")
    
    log_info "Uploading to OCI Object Storage..."
    
    if ! command -v oci &> /dev/null; then
        log_error "OCI CLI not found"
        return 1
    fi
    
    oci os object put \
        --namespace-name "$OCI_COMPARTMENT_ID" \
        --bucket-name "$OCI_BUCKET_NAME" \
        --file "$dump_path" \
        --object-name "supabase/${dump_filename}" \
        --content-encoding "gzip" \
        --force || true
    
    log_info "Uploaded: oci://${OCI_BUCKET_NAME}/supabase/${dump_filename}"
}

cleanup_oci_dumps() {
    if ! command -v oci &> /dev/null; then
        return 0
    fi
    
    log_info "Cleaning up OCI dumps (keeping $RETENTION)..."
    
    local objects
    objects=$(oci os object list \
        --namespace-name "$OCI_COMPARTMENT_ID" \
        --bucket-name "$OCI_BUCKET_NAME" \
        --prefix "supabase/${ENVIRONMENT}_supabase_dump_" \
        --query "data[].name" \
        --raw-output 2>/dev/null) || true
    
    if [[ -z "$objects" ]]; then
        return 0
    fi
    
    local object_count
    object_count=$(echo "$objects" | wc -l)
    
    if [[ $object_count -le $RETENTION ]]; then
        return 0
    fi
    
    echo "$objects" | head -n $((object_count - RETENTION)) | while read -r object; do
        if [[ -n "$object" ]]; then
            log_info "Deleting: $object"
            oci os object delete \
                --namespace-name "$OCI_COMPARTMENT_ID" \
                --bucket-name "$OCI_BUCKET_NAME" \
                --object-name "$object" \
                --force 2>/dev/null || true
        fi
    done
    
    log_info "OCI cleanup complete"
}

main() {
    log_info "=== Dumping Supabase: $ENVIRONMENT ==="
    
    ensure_dump_dir
    load_env
    
    local dump_path
    dump_path=$(dump_database)
    
    cleanup_local_dumps
    
    if [[ "$UPLOAD_TO_OCI" == "true" ]]; then
        ensure_oci_bucket
        upload_to_oci "$dump_path"
        cleanup_oci_dumps
    fi
    
    log_info "=== Dump complete ==="
    log_info "File: $dump_path"
}

main "$@"