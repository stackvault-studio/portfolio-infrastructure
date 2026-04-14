#!/bin/bash
# run.sh - Quick script to run docker compose with proper environment
# Usage: ./run.sh up ENV=dev

set -euo pipefail

ENV="${2:-dev}"
TARGET="${1:-up}"

if [[ ! -f "./load-env.sh" ]]; then
    echo "Error: load-env.sh not found"
    exit 1
fi

source ./load-env.sh "$ENV"

export ENVIRONMENT BACKEND_TAG FRONT_TAG BACKEND_IMAGE FRONT_IMAGE DB_HOST DB_PORT DB_NAME DB_USERNAME DB_PASSWORD SUPABASE_URL SUPABASE_ANON_KEY

DC_PROFILES=""
if [[ "$ENV" == "local" ]]; then
    DC_PROFILES="--profile local"
fi

docker compose -f docker-compose.yml $DC_PROFILES $TARGET -d
