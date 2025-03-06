#!/usr/bin/env bash
set -euo pipefail

source .github/scripts/env_validation.sh
source .github/scripts/config_parser.sh
source .github/scripts/check_pr_rules.sh
source .github/scripts/determine_env_and_deploy.sh
source .github/scripts/generate_tags.sh
source .github/scripts/build_matrix.sh

main() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --repo_name) REPO_NAME="$2"; shift ;;
            --base_ref)  BASE_REF="$2"; shift ;;
            --head_ref)  HEAD_REF="$2"; shift ;;
            --sha)       GITHUB_SHA="$2"; shift ;;
            --config)    CONFIG_FILE="$2"; shift ;;
            --registry)  REGISTRY="$2"; shift ;;
            *) echo "ERROR: Unknown parameter: $1" >&2; exit 1 ;;
        esac
        shift
    done

    # Validate arguments
    validate_args REPO_NAME BASE_REF HEAD_REF GITHUB_SHA CONFIG_FILE REGISTRY

    # Parse config
    parse_config "$CONFIG_FILE"

    # By default, we assume that the build is allowed
    PROCEED=true
    DEPLOY=false
    ENVIRONMENT="unknown"

    # Check PR rules
    check_pr_rules

    # Determine environment and deploy (dev/stage/prod) based on base_ref
    determine_env_and_deploy

    # If PR doesn't pass rules, we stop here
    [[ "$PROCEED" != "true" ]] && {
        {
            echo "proceed=false"
            echo "deploy=false"
            echo "environment=unknown"
            echo "deployment_list=[]"
            echo "tag_suffix="
            echo "tag_sha="
            echo "build_matrix={\"include\":[{\"context\":\".\"}]}"
            echo "docker_labels="
        } >> "$GITHUB_OUTPUT"
        exit 0
    }

    # Determine the list of utility repositories
    UTILS_LIST=(
    accounts
    api
    auth
    customer
    games
    images
    integrations
    notifications
    payments
    ranks
    security
    support
    tools
    user-stats
    )

    # Define the the utility repositories if needed
    if printf '%s\n' "${UTILS_LIST[@]}" | grep -qx "$REPO_NAME"; then
    NEEDS_UTILS="true"
    else
    NEEDS_UTILS="false"
    fi

    # Determine the list of migration repositories
    MIGRATION_SUBMODULE_LIST=(promotion bonuses)

    # Check if utils are needed for current repository
    MIGRATION_SUBMODULE="false"
    for item in "${MIGRATION_SUBMODULE_LIST[@]}"; do
    if [[ "$item" == "$REPO_NAME" ]]; then
        MIGRATION_SUBMODULE="true"
        break
    fi
    done
    
    # Generate tags if needed in case TAG_SUFFIX is already set logic may be not overwritten
    generate_tags

    # Set build matrix
    set_build_matrix

    # Summary output to Github output
    {
        echo "proceed=$PROCEED"
        echo "deploy=$DEPLOY"
        echo "environment=$ENVIRONMENT"
        echo "deployment_list=$DEPLOYMENTS"
        echo "tag_suffix=$TAG_SUFFIX"
        echo "tag_sha=$TAG_SHA"
        echo "build_matrix=$BUILD_MATRIX"
        echo "docker_labels=$DOCKER_LABELS"
        echo "needs_utils=$NEEDS_UTILS"
        echo "db_migration_submodule=$MIGRATION_SUBMODULE"
    } >> "$GITHUB_OUTPUT"
}

main "$@"