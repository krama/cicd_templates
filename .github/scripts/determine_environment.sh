#!/usr/bin/env bash
set -euo pipefail

determine_environment() {
    ENVIRONMENT="unknown"
    DEPLOY=false
    PROJECT=""

    if [[ ! -f "$GITHUB_EVENT_PATH" ]]; then
    echo "ERROR: Event path $GITHUB_EVENT_PATH not found." >&2
    exit 1
    fi

    # For workflow_dispatch, take the environment directly from input_env
    if [[ "${GITHUB_EVENT_NAME:-}" == "workflow_dispatch" && -f "$GITHUB_EVENT_PATH" ]]; then
        local input_env
        input_env=$(jq -r '.inputs.environment' "$GITHUB_EVENT_PATH")
        if [[ "$input_env" =~ ^(dev|stage|prod)-(.+)$ ]]; then
            ENVIRONMENT="${BASH_REMATCH[1]}"
            PROJECT="${BASH_REMATCH[2]}"
            DEPLOY=true
        fi
    # Else, analyze HEAD_REF
    elif [[ "$HEAD_REF" =~ ^(feature|fix)/ ]]; then
        ENVIRONMENT="dev"
        DEPLOY=true
    elif [[ "$HEAD_REF" == "staging" ]]; then
        ENVIRONMENT="stage"
        DEPLOY=true
    elif [[ "$HEAD_REF" == "main" ]]; then
        ENVIRONMENT="prod"
        DEPLOY=true
    elif [[ "$HEAD_REF" =~ ^hotfix/ ]]; then
    # List of allowed repositories for hotfix deployments
    ALLOWED_REPOS=("queen" "api")
    
    if [[ " ${ALLOWED_REPOS[@]} " =~ " ${REPO_NAME} " && "$BASE_REF" == "main" ]]; then
        ENVIRONMENT="prod"
        DEPLOY=true
        echo "Environment set to prod for hotfix branch in ${REPO_NAME}."
    else
        echo "Skipping build: hotfix branches allowed only for approved repositories merging into main." >&2
        echo "Approved repositories: ${ALLOWED_REPOS[*]}" >&2
        DEPLOY=false
        PROCEED=false
    fi
    fi

    # If it's not set, use default values
    DEPLOYMENTS=$(echo "$CONFIG" | jq -c ".environments.\"$ENVIRONMENT\".deployments" 2>/dev/null || echo "[]")
    if [[ -z "$DEPLOYMENTS" || "$DEPLOYMENTS" == "null" ]]; then
        DEPLOYMENTS="[]"
    fi

    if [[ -n "$PROJECT" ]]; then
        DEPLOYMENTS=$(echo "$DEPLOYMENTS" | jq -c "[.[] | select(.project == \"$PROJECT\")]")
    fi

    # Build tag suffix
    if [[ -n "$PROJECT" ]]; then
        TAG_SUFFIX="${ENVIRONMENT}-${PROJECT}"
    else
        TAG_SUFFIX="$ENVIRONMENT"
    fi

    if [[ -n "${GITHUB_SHA:-}" ]]; then
        TAG_SHA="$GITHUB_SHA"
    else
        echo "ERROR: GITHUB_SHA is not set" >&2
        exit 1
    fi
}
