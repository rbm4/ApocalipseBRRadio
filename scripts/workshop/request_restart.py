"""Notify pzmanager after publication without logging integration credentials."""
import json
import os
import sys
import urllib.parse
import urllib.request


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Never forward the integration token to a redirected destination.
        return None


def configuration():
    url = os.environ.get("PZMANAGER_RESTART_URL", "")
    token = os.environ.get("PZMANAGER_MOD_UPDATE_TOKEN", "")
    parsed = urllib.parse.urlsplit(url)
    if (parsed.scheme != "https" or not parsed.hostname or parsed.username
            or parsed.password or parsed.query or parsed.fragment
            or parsed.path != "/api/server/mod-update/restart" or not token
            or any(ord(c) < 32 or ord(c) == 127 for c in token)):
        raise ValueError("Invalid restart integration configuration")
    return url, token


def request_restart(url, token):
    request = urllib.request.Request(
        url, method="POST",
        data=json.dumps({"message": "Restart para update de mods"}).encode("utf-8"),
        headers={"Content-Type": "application/json", "X-Mod-Update-Token": token},
    )
    opener = urllib.request.build_opener(NoRedirect())
    with opener.open(request, timeout=30) as response:
        result = json.loads(response.read(4096))
        expected = {202: "accepted", 200: "already_in_progress"}
        if response.status not in expected or result.get("status") != expected[response.status]:
            raise ValueError("Unexpected restart response")
        print("Restart requested." if response.status == 202 else "Restart already in progress; duplicate discarded.")


def main():
    try:
        url, token = configuration()
        if sys.argv[1:] == ["--validate-only"]:
            print("Restart integration configuration is present.")
        elif not sys.argv[1:]:
            request_restart(url, token)
        else:
            raise ValueError("Unsupported arguments")
    except Exception:
        # Exceptions can contain URLs; do not expose secrets or response bodies.
        print("::error::Restart integration failed. Check the HTTPS endpoint, token and backend deployment. "
              "If Steam already published, request a restart separately rather than republishing.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
