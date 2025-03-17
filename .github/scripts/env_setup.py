#!/usr/bin/env python3
import argparse
import json
import logging
import os
import re
import sys

# Настройка логирования
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def validate_args(args, required_fields):
    missing = [field for field in required_fields if not getattr(args, field)]
    if missing:
        logging.error("Missing required arguments: %s", ", ".join(missing))
        sys.exit(1)

def parse_config(config_file):
    if not os.path.isfile(config_file):
        logging.error("Config file not found: %s", config_file)
        sys.exit(1)
    try:
        with open(config_file, "r") as f:
            config = json.load(f)
        logging.info("Configuration successfully loaded.")
        return config
    except Exception as e:
        logging.error("Failed to parse config file: %s", e)
        sys.exit(1)

def parse_labels(github_event_name, github_event_path):
    labels = {}
    if github_event_name == "workflow_dispatch" and os.path.isfile(github_event_path):
        try:
            with open(github_event_path, "r") as f:
                event = json.load(f)
            input_env = event.get("inputs", {}).get("environment", "")
            match = re.match(r"^(dev|stage|prod)-(.+)$", input_env)
            if match:
                labels["project"] = match.group(2)
                labels["environment_selector"] = input_env
                logging.info("Parsed workflow_dispatch labels: %s", labels)
            else:
                logging.error("Invalid environment format in workflow_dispatch. Expected <env>-<project>.")
                sys.exit(1)
        except Exception as e:
            logging.error("Error parsing event file: %s", e)
            sys.exit(1)
    else:
        logging.info("Not a workflow_dispatch event — skipping label parsing.")
    return labels

def determine_environment(head_ref, base_ref, github_sha, config):
    environment = "unknown"
    deploy = False
    project = ""
    # Логика определения окружения
    if head_ref.startswith("feature/") or head_ref.startswith("fix/"):
        environment = "dev"
        deploy = True
    elif head_ref == "staging":
        environment = "stage"
        deploy = True
    elif head_ref == "main":
        environment = "prod"
        deploy = True
    elif head_ref.startswith("hotfix/"):
        if base_ref == "main":
            environment = "prod"
            deploy = True
            logging.info("Environment set to prod for hotfix branch.")
        else:
            logging.error("Hotfix branches allowed only when merging into main.")
            deploy = False

    deployments = config.get("environments", {}).get(environment, {}).get("deployments", [])
    # Если определён project (например, из workflow_dispatch)
    if project:
        deployments = [d for d in deployments if d.get("project") == project]

    tag_suffix = f"{environment}-{project}" if project else environment
    if not github_sha:
        logging.error("GITHUB_SHA is not set.")
        sys.exit(1)
    tag_sha = github_sha

    return {
        "environment": environment,
        "deploy": deploy,
        "deployments": deployments,
        "tag_suffix": tag_suffix,
        "tag_sha": tag_sha
    }

def set_build_matrix(repo_name):
    if repo_name == "tools":
        matrix = {"include": [{"context": "app"}, {"context": "client"}, {"context": "db_migrations"}]}
    elif repo_name in ["leads", "promo"]:
        matrix = {"include": [{"context": "."}, {"context": "app/db_migrations"}]}
    elif repo_name in ["accounts", "game", "support", "users", "payments"]:
        matrix = {"include": [{"context": "."}, {"context": "db_migrations"}]}
    else:
        matrix = {"include": [{"context": "."}]}
    logging.info("Build matrix set: %s", matrix)
    return matrix

def set_namespace(deployments, project):
    namespace = ""
    if project:
        for deployment in deployments:
            if deployment.get("project") == project:
                namespace = deployment.get("namespace", "")
                break
    return namespace

def main():
    parser = argparse.ArgumentParser(description="Environment setup for CI/CD")
    parser.add_argument("--repo_name", required=True, help="Repository name")
    parser.add_argument("--base_ref", required=True, help="Base branch reference")
    parser.add_argument("--head_ref", required=True, help="Head branch reference")
    parser.add_argument("--sha", required=True, help="GitHub SHA")
    parser.add_argument("--config", required=True, help="Path to config file")
    parser.add_argument("--environment", help="Environment selector from workflow_dispatch", default="")
    args = parser.parse_args()

    validate_args(args, ["repo_name", "base_ref", "head_ref", "sha", "config"])
    config = parse_config(args.config)

    github_event_name = os.environ.get("GITHUB_EVENT_NAME", "")
    github_event_path = os.environ.get("GITHUB_EVENT_PATH", "")
    labels = parse_labels(github_event_name, github_event_path)
    project = labels.get("project", "")

    env_data = determine_environment(args.head_ref, args.base_ref, args.sha, config)
    build_matrix = set_build_matrix(args.repo_name)
    namespace = set_namespace(env_data["deployments"], project)

    output = {
        "proceed": env_data["deploy"],
        "deploy": env_data["deploy"],
        "environment": env_data["environment"],
        "deployment_list": env_data["deployments"],
        "tag_suffix": env_data["tag_suffix"],
        "tag_sha": env_data["tag_sha"],
        "build_matrix": build_matrix,
        "docker_labels": "",
        "namespace": namespace,
        "needs_utils": "true" if args.repo_name in ["accounts", "api", "auth", "customer", "games", "images", "integrations", "notifications", "payments", "ranks", "security", "support", "tools", "user-stats"] else "false",
        "db_migration_submodule": "true"  # Здесь можно добавить условную логику
    }

    # Вывод в формате, пригодном для GitHub Actions (ключ=значение)
    for key, value in output.items():
        if isinstance(value, (dict, list)):
            print(f"{key}={json.dumps(value)}")
        else:
            print(f"{key}={value}")

if __name__ == "__main__":
    main()
