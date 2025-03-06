#!/usr/bin/env bash
set -euo pipefail

check_pr_rules() {

    if [[ -z "$HEAD_REF" || -z "$BASE_REF" ]]; then
        echo "ERROR: HEAD_REF or BASE_REF is empty. Cannot proceed with PR rules check." >&2
        exit 1
    fi

    if [[ "${GITHUB_EVENT_NAME:-}" != "pull_request" ]]; then
        echo "Not a pull_request event. Skipping PR rules checks."
        PROCEED=true
        return
    fi

    if [[ "$REPO_NAME" == "queen" ]]; then
        if [[ "$HEAD_REF" == "staging" && "$BASE_REF" == "main" ]]; then
            PROCEED=true
            echo "Valid PR: staging -> main for "queen" repository."
        else
            PROCEED=false
            echo "Skipping build for queen repository: only PRs from 'staging' to 'main' are allowed."
        fi
        return
    fi

    # Code for feature/ and fix/
    if [[ "$HEAD_REF" =~ ^(feature|fix)/ ]]; then
        if [[ "$BASE_REF" == "staging" ]]; then
            PROCEED=true
            echo "Valid PR: $HEAD_REF -> staging."
        else
            PROCEED=false
            echo "Skipping build: PRs from 'feature/*' or 'fix/*' must target 'staging'."
        fi

    # Staging -> main
    elif [[ "$HEAD_REF" == "staging" ]]; then
        if [[ "$BASE_REF" == "main" ]]; then
            PROCEED=true
            echo "Valid PR: staging -> main."
        else
            PROCEED=false
            echo "Skipping build: PR from 'staging' must target 'main'."
        fi

    # hotfix/* -> main
    elif [[ "$HEAD_REF" =~ ^hotfix/ ]]; then
        if [[ "$BASE_REF" == "main" ]]; then
            PROCEED=true
            echo "Valid PR: hotfix -> main."
        else
            PROCEED=false
            echo "Skipping build: PR from 'hotfix/*' must target 'main'."
        fi

    # Else reject
    else
        PROCEED=false
        echo "Skipping build: PR does not meet any of the required rules."
    fi
}
