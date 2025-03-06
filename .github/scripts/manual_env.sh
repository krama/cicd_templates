#!/usr/bin/env bash
set -euo pipefail

# Connect our helper files.
source .github/scripts/env_validation.sh
source .github/scripts/config_parser.sh
source .github/scripts/labels_parser.sh
source .github/scripts/determine_environment.sh
source .github/scripts/build_matrix.sh
source .github/scripts/namespace_helper.sh

main() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --repo_name)     REPO_NAME="$2"; shift ;;
            --base_ref)      BASE_REF="$2"; shift ;;
            --head_ref)      HEAD_REF="$2"; shift ;;
            --sha)           GITHUB_SHA="$2"; shift ;;
            --config)        CONFIG_FILE="$2"; shift ;;
            --environment)   ENVIRONMENT_SELECTOR="$2"; shift ;;
            --registry)      REGISTRY="$2"; shift ;;
            *) echo "ERROR: Unknown parameter: $1" >&2; exit 1 ;;
        esac
        shift
    done
    # Set the list of utility repositories
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

    # Compare the list of utility for the current repository
    NEEDS_UTILS="false"
    for item in "${UTILS_LIST[@]}"; do
    if [[ "$item" == "$REPO_NAME" ]]; then
        NEEDS_UTILS="true"
        break
    fi
    done

    # Set the list of repos for migration submodule
    MIGRATION_SUBMODULE_LIST=(promotion bonuses)

    # Compare the list of utility for the current repository
    MIGRATION_SUBMODULE="false"
    for item in "${MIGRATION_SUBMODULE_LIST[@]}"; do
    if [[ "$item" == "$REPO_NAME" ]]; then
        MIGRATION_SUBMODULE="true"
        break
    fi
    done

    # Validate required arguments
    validate_args REPO_NAME HEAD_REF GITHUB_SHA CONFIG_FILE REGISTRY

    # Parse config
    parse_config "$CONFIG_FILE"

    # Parse labels (only for workflow_dispatch)
    parse_labels

    # Determine ENVIRONMENT, DEPLOY, TAG_SUFFIX
    determine_environment

    # Creating build-matrix
    set_build_matrix

    # Setting namespace if manual run
    set_label_namespace_from_json

    # Forming the final output
    {
        echo "proceed=$DEPLOY"
        echo "deploy=$DEPLOY"
        echo "environment=$ENVIRONMENT"
        echo "deployment_list=$DEPLOYMENTS"
        echo "tag_suffix=$TAG_SUFFIX"
        echo "tag_sha=$TAG_SHA"
        echo "build_matrix=$BUILD_MATRIX"
        echo "docker_labels="
        echo "namespace=${NAMESPACE:-}"
        echo "needs_utils=$NEEDS_UTILS"
        echo "db_migration_submodule=$MIGRATION_SUBMODULE"
    } >> "$GITHUB_OUTPUT"
}

main "$@"