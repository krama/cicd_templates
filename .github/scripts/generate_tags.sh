#!/usr/bin/env bash
set -euo pipefail

# Function to centralize logic
generate_tags() {
    local branch_ref="$BASE_REF"
    local head_ref="$HEAD_REF"

    if [[ -z "${TAG_SUFFIX:-}" ]]; then
    case "$branch_ref" in
        "main")
            TAG_SUFFIX="latest"
            TAG_SHA="mn-${GITHUB_SHA}"
            ;;
        "staging")
            TAG_SUFFIX="staging"
            TAG_SHA="st-${GITHUB_SHA}"
            ;;
        hotfix/*)
            # Changes: For all hotfix branches, remove the check on REPO_NAME
            local branch_name_clean="${head_ref//\//-}"
            TAG_SUFFIX="${branch_name_clean}"
            TAG_SHA="hf-${branch_name_clean}-${GITHUB_SHA}"
            ;;
        feature/*)
            local branch_name_clean="${head_ref//\//-}"
            TAG_SUFFIX="${branch_name_clean}"
            TAG_SHA="ft-${branch_name_clean}-${GITHUB_SHA}"
            ;;
        *)
            echo "No matching branch found, skipping Docker tag setting." >&2
            return 0
            ;;
    esac
    fi

    DOCKER_LABELS=""
    if [[ "$TAG_SUFFIX" =~ ^(latest|staging|develop)$ ]]; then
        DOCKER_LABELS="org.opencontainers.image.version=${TAG_SUFFIX}"
    fi
}
