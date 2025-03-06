#!/usr/bin/env bash
set -euo pipefail

# Small function to set build matrix
set_build_matrix() {
    case "$REPO_NAME" in
        "tools")
            BUILD_MATRIX='{"include":[{"context":"app"},{"context":"client"},{"context":"db_migrations"}]}'
            ;;
        "leads"|"promo")
            BUILD_MATRIX='{"include":[{"context":"."},{"context":"app/db_migrations"}]}'
            ;;
        "accounts"|"game"|"support" | "users"| "payments")
            BUILD_MATRIX='{"include":[{"context":"."},{"context":"db_migrations"}]}'
            ;;
        *)
            BUILD_MATRIX='{"include":[{"context":"."}]}'
            ;;
    esac
}