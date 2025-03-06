#!/usr/bin/env bash
source ".github/scripts/common.sh"
# Converts a job status into an emoji.
get_status_emoji() {
  local status="${1,,}"
  case "$status" in
    failure|failed) echo "❌" ;;
    success|passed) echo "✅" ;;
    pending|running) echo "⏳" ;;
    cancelled) echo "🚫" ;;
    *) echo "❔" ;;
  esac
}
# Script parameters:
REPOSITORY="$1"
ACTOR="$2"
BUILD_BRANCH="$3"
ENVIRONMENT="$4"
WORKFLOW_URL="$5"
VALIDATE_ENV_STATUS="$6"
BUILD_STATUS="$7"
DEPLOY_STATUS="$8"

MESSAGE="🚨 PIPELINE RUN ERROR 🚨

Jobs Status:  
VALIDATE_ENV: $(get_status_emoji "$VALIDATE_ENV_STATUS")  
BUILD: $(get_status_emoji "$BUILD_STATUS")  
DEPLOY: $(get_status_emoji "$DEPLOY_STATUS")

Repository: $REPOSITORY  
Author: $ACTOR  
Branch: $BUILD_BRANCH  
Environment: $ENVIRONMENT

Action link: $WORKFLOW_URL"

# Create JSON using jq
PAYLOAD=$(jq -n --arg msg "$MESSAGE" --compact-output '{
  icon_emoji: ":robot:",
  attachments: [
    {
      "text": $msg
    }
  ]
}')

# Output the JSON to stdout
echo "$PAYLOAD"