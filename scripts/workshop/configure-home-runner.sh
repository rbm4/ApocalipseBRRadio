#!/usr/bin/env bash
# Register an already downloaded, checksum-verified official Linux x64 runner.
set -euo pipefail
runner_directory=${1:-$HOME/actions-runner}
runner_url=${2:-https://github.com/ApocalipseBr/ApocalipseBRRadio}
[[ $EUID -ne 0 ]] || { echo "Run as your ordinary WSL user, not root." >&2; exit 1; }
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || { echo "A Linux x64 runner is required." >&2; exit 1; }
[[ "$runner_url" =~ ^https://github\.com/[A-Za-z0-9_-]+(/[A-Za-z0-9_.-]+)?$ ]] || { echo "Supply a GitHub repository or organization URL." >&2; exit 1; }
for tool in docker python3 gh; do
  command -v "$tool" >/dev/null || { echo "Install $tool in this Linux distribution first." >&2; exit 1; }
done
docker info >/dev/null 2>&1 || { echo "Start Docker and allow this user to access its daemon; verify docker info." >&2; exit 1; }
cd "$runner_directory"
[[ -x ./config.sh && -x ./run.sh ]] || { echo "Download and verify the official Linux x64 runner into $runner_directory first." >&2; exit 1; }
[[ ! -f .runner ]] || { echo "This runner is already registered. Start it with ./run.sh instead." >&2; exit 1; }
[[ -t 0 ]] || { echo "Run interactively to enter the short-lived registration token." >&2; exit 1; }
trap 'unset registration_token' EXIT
read -r -s -p "GitHub runner registration token (hidden): " registration_token
printf '\n'
[[ -n "$registration_token" ]] || { echo "A registration token is required." >&2; exit 1; }
./config.sh --unattended --url "$runner_url" --token "$registration_token" \
  --name "$(hostname)-pz-workshop" --labels pz-workshop --work _work
unset registration_token
for credential_file in .runner .credentials .credentials_rsaparams; do
  if [[ -f "$credential_file" ]]; then chmod 600 "$credential_file"; fi
done
printf 'Runner registered. Start it from %s with ./run.sh, or install its systemd service.\n' "$runner_directory"
