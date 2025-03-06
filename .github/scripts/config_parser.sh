#!/usr/bin/env bash
set -euo pipefail

# Function to parse JSON config
parse_config() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        echo "ERROR: Config file not found: $config_file" >&2
        return 1
    fi

    CONFIG=$(jq '.' "$config_file") || {
        echo "ERROR: Failed to parse config file: $config_file" >&2
        return 1
    }
}