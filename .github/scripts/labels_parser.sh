#!/usr/bin/env bash
set -euo pipefail

parse_labels() {
    echo "Debug: Starting parse_labels function"

    if [[ "${GITHUB_EVENT_NAME:-}" == "workflow_dispatch" ]]; then
        if [[ -f "$GITHUB_EVENT_PATH" ]]; then
            local input_env
            input_env=$(jq -r '.inputs.environment' "$GITHUB_EVENT_PATH")
            if [[ "$input_env" =~ ^(dev|stage|prod)-(.+)$ ]]; then
                PR_LABELS="${BASH_REMATCH[2]}"
                ENVIRONMENT_SELECTOR="$input_env"
                echo "Debug: Found environment from workflow_dispatch: $ENVIRONMENT_SELECTOR"
                return 0
            else
                echo "ERROR: Invalid or empty environment format in workflow_dispatch. Expected <env>-<project>." >&2
                exit 1
            fi
        else
            echo "ERROR: GITHUB_EVENT_PATH not found for workflow_dispatch." >&2
            exit 1
        fi
    else
        echo "Debug: Not a workflow_dispatch event — skipping parse of environment/labels."
        return 0
    fi
}