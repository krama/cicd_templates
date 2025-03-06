#!/usr/bin/env bash
set -euo pipefail

# Function to find namespace in json config based on environment and project (if workflow_dispatch)
set_label_namespace_from_json() {
    NAMESPACE=""

    if [[ "${GITHUB_EVENT_NAME:-}" == "workflow_dispatch" ]]; then
        if [[ -f "$GITHUB_EVENT_PATH" ]]; then
            local input_env
            input_env=$(jq -r '.inputs.environment' "$GITHUB_EVENT_PATH")
            if [[ "$input_env" =~ ^(dev|stage|prod)-(.+)$ ]]; then
                local project="${BASH_REMATCH[2]}"
                local deployment
                deployment="$(echo "$DEPLOYMENTS" | jq -c ". | map(select(.project == \"$project\")) | first")"
                if [[ -n "$deployment" && "$deployment" != "null" ]]; then
                    NAMESPACE=$(echo "$deployment" | jq -r '.namespace')
                else
                    echo "ERROR: Could not find deployment configuration for environment: $input_env" >&2
                    exit 1
                fi
            else
                echo "ERROR: Invalid environment format: $input_env. Expected format: <env>-<project>" >&2
                exit 1
            fi
        fi
    fi
}