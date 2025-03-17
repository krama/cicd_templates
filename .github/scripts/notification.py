#!/usr/bin/env python3
import argparse
import json
import logging

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def generate_notification(repo, actor, branch, environment, workflow_url, validate_status, build_status, deploy_status):
    status_emoji = {
        "failure": "❌",
        "failed": "❌",
        "success": "✅",
        "passed": "✅",
        "pending": "⏳",
        "running": "⏳",
        "cancelled": "🚫"
    }
    def get_status_emoji(status):
        return status_emoji.get(status.lower(), "❔")

    message = (
        "🚨 PIPELINE RUN ERROR 🚨\n\n"
        f"Jobs Status:\n"
        f"VALIDATE_ENV: {get_status_emoji(validate_status)}\n"
        f"BUILD: {get_status_emoji(build_status)}\n"
        f"DEPLOY: {get_status_emoji(deploy_status)}\n\n"
        f"Repository: {repo}\n"
        f"Author: {actor}\n"
        f"Branch: {branch}\n"
        f"Environment: {environment}\n\n"
        f"Action link: {workflow_url}"
    )

    payload = {
        "icon_emoji": ":robot:",
        "attachments": [
            {
                "text": message,
                "mrkdwn": True
            }
        ]
    }
    return payload

def main():
    parser = argparse.ArgumentParser(description="Generate notification payload for Rocket.Chat")
    parser.add_argument("--repo", required=True, help="Repository name")
    parser.add_argument("--actor", required=True, help="Author/Actor")
    parser.add_argument("--branch", required=True, help="Build branch")
    parser.add_argument("--environment", required=True, help="Environment")
    parser.add_argument("--workflow_url", required=True, help="URL to the workflow run")
    parser.add_argument("--validate_status", required=True, help="Validation job status")
    parser.add_argument("--build_status", required=True, help="Build job status")
    parser.add_argument("--deploy_status", required=True, help="Deploy job status")
    args = parser.parse_args()

    payload = generate_notification(
        args.repo, args.actor, args.branch, args.environment,
        args.workflow_url, args.validate_status, args.build_status, args.deploy_status
    )
    print(json.dumps(payload))

if __name__ == "__main__":
    main()
