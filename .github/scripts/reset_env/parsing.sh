#!/usr/bin/env bash
set -euo pipefail

INPUT_ENV="$1"
CONFIG_PATH="$2"

CONFIG=$(jq '.' "$CONFIG_PATH")

case "$INPUT_ENV" in
    "All")
        DEPLOYMENTS=$(jq -c '[.environments.stage.deployments[], .environments.dev.deployments[]]' <<< "$CONFIG")
        ;;
    "All stage")
        DEPLOYMENTS=$(jq -c '[.environments.stage.deployments[]]' <<< "$CONFIG")
        ;;
    "All dev")
        DEPLOYMENTS=$(jq -c '[.environments.dev.deployments[]]' <<< "$CONFIG")
        ;;
    *)
        DEPLOYMENTS=$(jq -c --arg ns "$INPUT_ENV" '[.environments[].deployments[] | select(.namespace == $ns)]' <<< "$CONFIG")
        ;;
esac

# If the variable is empty, return "[]"
if [ -z "$DEPLOYMENTS" ]; then
  DEPLOYMENTS="[]"
fi

# Output debug info to stderr
echo "Selected environment: $INPUT_ENV" >&2
TOTAL_COUNT=$(echo "$DEPLOYMENTS" | jq 'length')
echo "Found $TOTAL_COUNT deployment(s)" >&2

# Output JSON to stdout
echo "$DEPLOYMENTS"
