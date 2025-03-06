#!/usr/bin/env bash
set -euo pipefail

determine_env_and_deploy() {
    case "$BASE_REF" in
        "development") ENVIRONMENT="dev"; DEPLOY=true ;;
        "staging")     ENVIRONMENT="stage"; DEPLOY=true ;;
        "main")        ENVIRONMENT="prod"; DEPLOY=true ;;
        *)             PROCEED=false; DEPLOY=false; ENVIRONMENT="unknown" ;;
    esac

    DEPLOYMENTS=$(echo "$CONFIG" | jq -c ".environments.\"$ENVIRONMENT\".deployments")
    if [[ -z "$DEPLOYMENTS" || "$DEPLOYMENTS" == "null" ]]; then
        DEPLOY=false
        DEPLOYMENTS="[]"
    fi
}