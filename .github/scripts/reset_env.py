#!/usr/bin/env python3
import argparse
import json
import logging
import sys

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def parse_deployments(input_env, config_path):
    try:
        with open(config_path, "r") as f:
            config = json.load(f)
    except Exception as e:
        logging.error("Failed to load config: %s", e)
        sys.exit(1)

    environments = config.get("environments", {})
    deployments = []
    if input_env in ["All"]:
        deployments = environments.get("stage", {}).get("deployments", []) + environments.get("dev", {}).get("deployments", [])
    elif input_env in ["All stage"]:
        deployments = environments.get("stage", {}).get("deployments", [])
    elif input_env in ["All dev"]:
        deployments = environments.get("dev", {}).get("deployments", [])
    else:
        for env in environments.values():
            for dep in env.get("deployments", []):
                if dep.get("namespace") == input_env:
                    deployments.append(dep)
    logging.info("Selected environment: %s", input_env)
    logging.info("Found %d deployment(s)", len(deployments))
    return deployments

def main():
    parser = argparse.ArgumentParser(description="Reset environment deployments parser")
    parser.add_argument("--input_env", required=True, help="Input environment (e.g. All, All stage, stage-alice, etc.)")
    parser.add_argument("--config", required=True, help="Path to config file")
    args = parser.parse_args()

    deployments = parse_deployments(args.input_env, args.config)
    print(json.dumps(deployments))

if __name__ == "__main__":
    main()
