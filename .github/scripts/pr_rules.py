#!/usr/bin/env python3
import argparse
import logging
import re
import sys

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def check_pr_rules(head_ref, base_ref, repo_name):
    if repo_name == "queen":
        if head_ref == "staging" and base_ref == "main":
            logging.info("Valid PR: staging -> main for queen repository.")
            return True
        else:
            logging.error("Invalid PR: Only PRs from 'staging' to 'main' are allowed for queen repository.")
            return False
    if re.match(r"^(feature|fix)/", head_ref):
        if base_ref == "staging":
            logging.info("Valid PR: %s -> staging.", head_ref)
            return True
        else:
            logging.error("Invalid PR: PRs from 'feature/*' or 'fix/*' must target 'staging'.")
            return False
    if head_ref == "staging":
        if base_ref == "main":
            logging.info("Valid PR: staging -> main.")
            return True
        else:
            logging.error("Invalid PR: PR from 'staging' must target 'main'.")
            return False
    if re.match(r"^hotfix/", head_ref):
        if base_ref == "main":
            logging.info("Valid PR: hotfix -> main.")
            return True
        else:
            logging.error("Invalid PR: PR from 'hotfix/*' must target 'main'.")
            return False

    logging.error("Invalid PR: PR does not meet any of the required rules.")
    return False

def main():
    parser = argparse.ArgumentParser(description="PR rules validation")
    parser.add_argument("--head_ref", required=True, help="Head branch reference")
    parser.add_argument("--base_ref", required=True, help="Base branch reference")
    parser.add_argument("--repo_name", required=True, help="Repository name")
    args = parser.parse_args()

    if not check_pr_rules(args.head_ref, args.base_ref, args.repo_name):
        sys.exit(1)
    sys.exit(0)

if __name__ == "__main__":
    main()
