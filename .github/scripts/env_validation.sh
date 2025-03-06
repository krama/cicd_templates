#!/usr/bin/env bash
set -euo pipefail

error() {
    echo "ERROR: $*" >&2
    exit 1
}

validate_args() {
    local -a required_args=("$@")
    for arg in "${required_args[@]}"; do
        if [[ -z "${!arg:-}" ]]; then
            error "$arg is not set"
            return 1
        fi
    done
}