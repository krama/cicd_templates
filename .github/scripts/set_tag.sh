#!/bin/bash

# Enable strict mode
set -euo pipefail

# Function to output messages to stderr
log() {
    echo "$1" >&2
}

# Function to output JSON-formatted result
output_json() {
    local image_updated="$1"
    printf '{"imageUpdated": "%s"}\n' "$image_updated"
}

# Validate input parameters
if [ "$#" -ne 3 ]; then
    log "Error: Invalid number of arguments"
    log "Usage: $0 <NAMESPACE> <REPO_NAME> <ENV_TAG>"
    exit 1
fi

NAMESPACE="$1"
REPO_NAME="$2"
ENV_TAG="$3"

# Initialize update flag
image_updated="false"

# Log deployment check
log "Checking deployment: $REPO_NAME"

# Get deployment JSON
if ! deployment_json=$(kubectl get deployment "$REPO_NAME" -n "$NAMESPACE" -o json 2>/dev/null); then
    log "Error: Failed to get deployment $REPO_NAME in namespace $NAMESPACE"
    output_json "false"
    exit 1
fi

# Extract containers using jq and process them
if ! containers=$(echo "$deployment_json" | jq -r '.spec.template.spec.containers[] | @base64'); then
    log "Error: Failed to parse deployment JSON"
    output_json "false"
    exit 1
fi

# Process each container
while read -r container_b64; do
    # Skip empty lines
    [ -z "$container_b64" ] && continue
    
    # Decode container JSON
    container=$(echo "$container_b64" | base64 --decode)
    
    # Extract container details
    CONTAINER_NAME=$(echo "$container" | jq -r '.name')
    CURRENT_IMAGE=$(echo "$container" | jq -r '.image')
    
    # Split image into repository and tag
    CURRENT_TAG=$(echo "$CURRENT_IMAGE" | awk -F':' '{print $NF}')
    CURRENT_REPO=$(echo "$CURRENT_IMAGE" | awk -F':' '{print $1}')
    
    # Log container details
    log "Container: $CONTAINER_NAME"
    log "Current image: $CURRENT_IMAGE"
    log "Current tag: $CURRENT_TAG"
    log "Expected tag: $ENV_TAG"
    
    # Check if tag update is needed
    if [ "$CURRENT_TAG" != "$ENV_TAG" ]; then
        NEW_IMAGE="${CURRENT_REPO}:${ENV_TAG}"
        log "Updating image for container $CONTAINER_NAME to $NEW_IMAGE"
        
        if kubectl set image deployment/"$REPO_NAME" -n "$NAMESPACE" "$CONTAINER_NAME=$NEW_IMAGE"; then
            image_updated="true"
            log "Successfully updated image for $CONTAINER_NAME"
        else
            log "Error: Failed to update image for container $CONTAINER_NAME"
            output_json "false"
            exit 1
        fi
    else
        log "Image tag is already up to date ($ENV_TAG)"
    fi
done <<< "$containers"

# Output final result
output_json "$image_updated"