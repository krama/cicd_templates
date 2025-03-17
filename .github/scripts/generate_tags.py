#!/usr/bin/env python3
import argparse
import logging
import re
import sys

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def generate_tags(head_ref, base_ref, github_sha):
    tag_suffix = ""
    tag_sha = ""
    if base_ref == "main":
        tag_suffix = "latest"
        tag_sha = f"mn-{github_sha}"
    elif base_ref == "staging":
        tag_suffix = "staging"
        tag_sha = f"st-{github_sha}"
    elif re.match(r"^hotfix/", head_ref):
        branch_clean = head_ref.replace("/", "-")
        tag_suffix = branch_clean
        tag_sha = f"hf-{branch_clean}-{github_sha}"
    elif re.match(r"^feature/", head_ref):
        branch_clean = head_ref.replace("/", "-")
        tag_suffix = branch_clean
        tag_sha = f"ft-{branch_clean}-{github_sha}"
    else:
        logging.error("No matching branch found for Docker tag generation.")
        sys.exit(1)
    return tag_suffix, tag_sha

def main():
    parser = argparse.ArgumentParser(description="Generate Docker tags")
    parser.add_argument("--head_ref", required=True, help="Head branch reference")
    parser.add_argument("--base_ref", required=True, help="Base branch reference")
    parser.add_argument("--sha", required=True, help="GitHub SHA")
    args = parser.parse_args()

    tag_suffix, tag_sha = generate_tags(args.head_ref, args.base_ref, args.sha)
    print(f"tag_suffix={tag_suffix}")
    print(f"tag_sha={tag_sha}")

if __name__ == "__main__":
    main()
