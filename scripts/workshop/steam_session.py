"""Persist SteamCMD's remembered-login config in an organization Actions secret."""
import base64
import binascii
import json
import os
from pathlib import Path
import re
import subprocess
import sys


class SessionError(Exception):
    """Only internally authored messages may be shown in Actions logs."""


def gh(arguments, data=None):
    operation = "write organization session secret" if arguments[0] == "secret" else (
        "read selected repository access" if arguments[-1].endswith("/repositories") else
        "read organization encryption key" if arguments[-1].endswith("/public-key") else
        "read organization session secret metadata")
    try:
        result = subprocess.run(["gh", *arguments], input=data, capture_output=True, check=True, timeout=90)
    except subprocess.CalledProcessError as error:
        # Extract only the numeric status. Raw gh output may contain sensitive data.
        raw = error.stderr or b""
        if isinstance(raw, bytes):
            raw = raw.decode("utf-8", errors="replace")
        match = re.search(r"HTTP ([1-5][0-9]{2})\b", raw)
        status = " (HTTP " + match.group(1) + ")" if match else ""
        raise SessionError("GitHub could not " + operation + status +
                           ". Check the token resource owner, approval/expiry and organization Secrets permissions.") from None
    except subprocess.TimeoutExpired:
        raise SessionError("GitHub timed out while attempting to " + operation + ".") from None
    except FileNotFoundError:
        raise SessionError("GitHub CLI (gh) is not installed on the runner.") from None
    return result.stdout


def configuration():
    org = os.environ.get("STEAM_SECRETS_ORGANIZATION", "")
    encoded = os.environ.get("STEAM_CONFIG_VDF", "").strip()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,38}", org):
        raise SessionError("STEAM_SECRETS_ORGANIZATION is missing or invalid.")
    if not os.environ.get("GH_TOKEN"):
        raise SessionError("STEAM_SESSION_GITHUB_TOKEN is missing or unavailable to this repository.")
    if not encoded:
        raise SessionError("STEAM_CONFIG_VDF is missing or unavailable to this repository.")
    try:
        config = base64.b64decode(encoded, validate=True)
    except (binascii.Error, ValueError):
        raise SessionError("STEAM_CONFIG_VDF must contain base64 of the config.vdf file, not its path or raw contents.") from None
    if not config or len(config) > 32768:
        raise SessionError("Decoded STEAM_CONFIG_VDF must contain between 1 byte and 32 KiB.")
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
    except SessionError as error:
        print("::error::" + str(error))
        return 1
    except Exception:
        print("::error::Steam session secret operation failed. Check STEAM_CONFIG_VDF and "
              "STEAM_SESSION_GITHUB_TOKEN organization Secrets permissions. No session data was logged.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
