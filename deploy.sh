#!/bin/bash

# =============================================================================
# deploy.sh - Deploy portfolio to specified environment
# =============================================================================
# Usage:
#   ./deploy.sh local
#   ./deploy.sh dev
#   ./deploy.sh staging
#   ./deploy.sh prod
# =============================================================================

set -euo pipefail

ENVIRONMENT="${1:-}"
VALID_ENV="local dev staging prod"

if [[ -z "$ENVIRONMENT" ]]; then
    echo "Usage: $0 <env>"
    echo "Valid envs: $VALID_ENV"
    exit 1
fi

if [[ ! " $VALID_ENV " =~ " $ENVIRONMENT " ]]; then
    echo "Invalid environment: $ENVIRONMENT"
    echo "Valid: $VALID_ENV"
    exit 1
fi

DOCKERHUB_IMAGE="ossemaabd95/stackvault"
ENV_FILE=".env.${ENVIRONMENT}"

echo "=== Deploying to: $ENVIRONMENT ==="

# Step 1: Fetch latest tags from DockerHub
echo ""
echo "Fetching latest tags from DockerHub..."
TAGS=$(curl -s "https://hub.docker.com/v2/repositories/${DOCKERHUB_IMAGE}/tags?page_size=10" | jq -r '.results[:10][] | "\(.name)"' 2>/dev/null || echo "")

if [[ -z "$TAGS" ]]; then
    echo "Warning: Could not fetch tags from DockerHub, using current config"
    LATEST_TAG=""
else
    echo "Available tags:"
    echo "$TAGS" | head -5
    LATEST_TAG=$(echo "$TAGS" | head -1)
    echo "Latest tag: $LATEST_TAG"
fi

# Step 2: Show current tags
if [[ -f "$ENV_FILE" ]]; then
    CURRENT_BACKEND=$(grep "^BACKEND_TAG=" "$ENV_FILE" | cut -d= -f2)
    CURRENT_FRONT=$(grep "^FRONT_TAG=" "$ENV_FILE" | cut -d= -f2)
    echo ""
    echo "Current tags in $ENV_FILE:"
    echo "  BACKEND_TAG=$CURRENT_BACKEND"
    echo "  FRONT_TAG=$CURRENT_FRONT"
else
    echo "Error: $ENV_FILE not found"
    exit 1
fi

# Step 3: Ask confirmation
if [[ -n "$LATEST_TAG" && "$LATEST_TAG" != "$CURRENT_BACKEND" ]]; then
    echo ""
    read -p "Update to tag '$LATEST_TAG' and deploy? (y/n) " -n 1 -r REPLY
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 0
    fi
    
    # Update tags
    sed -i "s/BACKEND_TAG=.*/BACKEND_TAG=${LATEST_TAG}/" "$ENV_FILE"
    sed -i "s/FRONT_TAG=.*/FRONT_TAG=${LATEST_TAG}/" "$ENV_FILE"
    echo "Updated $ENV_FILE with tag: $LATEST_TAG"
else
    echo "No update needed, deploying with current tags..."
fi

# Step 4: Deploy
echo ""
echo "Running deployment..."
make up ENV="$ENVIRONMENT"

echo ""
echo "=== Deployment complete ==="