#!/usr/bin/env python3
import argparse
import json
import logging
import subprocess
import sys

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def run_command(command):
    try:
        result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        logging.error("Command failed: %s\n%s", command, e.stderr)
        sys.exit(1)

def get_deployment_json(namespace, repo_name):
    cmd = f"kubectl get deployment {repo_name} -n {namespace} -o json"
    return run_command(cmd)

def update_container_image(namespace, repo_name, container_name, new_image):
    cmd = f"kubectl set image deployment/{repo_name} -n {namespace} {container_name}={new_image}"
    run_command(cmd)
    logging.info("Updated image for container %s to %s", container_name, new_image)

def set_tag(namespace, repo_name, env_tag):
    deployment_json = json.loads(get_deployment_json(namespace, repo_name))
    updated = False
    containers = deployment_json.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
    for container in containers:
        container_name = container.get("name")
        current_image = container.get("image")
        if ":" in current_image:
            current_tag = current_image.split(":")[-1]
        else:
            current_tag = "latest"
        if current_tag != env_tag:
            new_image = f"{current_image.split(':')[0]}:{env_tag}"
            logging.info("Updating container %s: current tag %s -> new tag %s", container_name, current_tag, env_tag)
            update_container_image(namespace, repo_name, container_name, new_image)
            updated = True
        else:
            logging.info("Container %s already uses tag %s", container_name, env_tag)
    print(json.dumps({"imageUpdated": str(updated).lower()}))

def main():
    parser = argparse.ArgumentParser(description="Set Docker tag in Kubernetes deployment")
    parser.add_argument("--namespace", required=True, help="Kubernetes namespace")
    parser.add_argument("--repo_name", required=True, help="Repository (deployment) name")
    parser.add_argument("--env_tag", required=True, help="Expected environment tag")
    args = parser.parse_args()
    set_tag(args.namespace, args.repo_name, args.env_tag)

if __name__ == "__main__":
    main()
