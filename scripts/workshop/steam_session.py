"""Persist SteamCMD's remembered-login config in an organization Actions secret."""
import base64
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def gh(arguments, data=None):
    result = subprocess.run(["gh", *arguments], input=data, capture_output=True, check=True, timeout=90)
    return result.stdout


def configuration():
    org = os.environ.get("STEAM_SECRETS_ORGANIZATION", "")
    encoded = os.environ.get("STEAM_CONFIG_VDF", "")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,38}", org) or not os.environ.get("GH_TOKEN"):
        raise ValueError("Organization and secret writer credential required")
    config = base64.b64decode(encoded, validate=True)
    if not config or len(config) > 32768:
        raise ValueError("Steam config is missing or too large")
    return org


def secret_policy(org):
    metadata = json.loads(gh(["api", f"orgs/{org}/actions/secrets/STEAM_CONFIG_VDF"]))
    visibility = metadata["visibility"]
    if visibility not in {"all", "private", "selected"}:
        raise ValueError("Unknown secret visibility")
    repositories = []
    if visibility == "selected":
        pages = json.loads(gh(["api", "--paginate", "--slurp",
                              f"orgs/{org}/actions/secrets/STEAM_CONFIG_VDF/repositories"]))
        repositories = [repo["name"] for page in pages for repo in page["repositories"]]
        if not repositories:
            raise ValueError("Steam config has no permitted repositories")
    # Check access to the encryption key before launching SteamCMD.
    gh(["api", f"orgs/{org}/actions/secrets/public-key"])
    return visibility, repositories


def save(org, file):
    config = Path(file).read_bytes()
    if not config or len(config) > 32768:
        raise ValueError("Invalid refreshed Steam config")
    visibility, repositories = secret_policy(org)
    arguments = ["secret", "set", "STEAM_CONFIG_VDF", "--org", org, "--visibility", visibility]
    if repositories:
        arguments += ["--repos", ",".join(repositories)]
    # gh encrypts to GitHub's organization public key. Value travels only over stdin.
    gh(arguments, base64.b64encode(config))


def main():
    try:
        org = configuration()
        if sys.argv[1:] == ["--validate-only"]:
            secret_policy(org)
            print("Steam session secret configuration checked.")
        elif len(sys.argv) == 3 and sys.argv[1] == "--save":
            save(org, sys.argv[2])
            print("Refreshed Steam session stored in the organization secret.")
        else:
            raise ValueError("Unsupported arguments")
    except Exception:
        print("::error::Steam session secret operation failed. Check STEAM_CONFIG_VDF and "
              "STEAM_SESSION_GITHUB_TOKEN organization Secrets permissions. No session data was logged.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
