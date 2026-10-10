#!/usr/bin/env bash
set -euo pipefail

tools_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(python3 "$tools_dir/stage.py" resolve "$GITHUB_WORKSPACE" "$PROJECT_DIRECTORY")"
workshop_dir="$project_dir"

case "$BUILD_MODE" in
  ready)
    ;;
  pzstudio)
    if [[ ! -f "$project_dir/package.json" || ! -f "$project_dir/project.json" ]]; then
      echo "::error::pzstudio mode requires package.json and project.json."
      exit 1
    fi
    cd "$project_dir"
    if [[ -f package-lock.json ]]; then
      npm ci
    else
      npm install
    fi
    npm install --no-save --package-lock=false pzstudio@2.2.0
    build_root="$RUNNER_TEMP/pzstudio-output"
    mkdir -p "$build_root"
    ./node_modules/.bin/pzstudio outdir "$build_root"
    npm run build
    workshop_dir="$(python3 "$tools_dir/stage.py" output "$build_root" "$project_dir/project.json")"
    ;;
  *)
    echo "::error::build-mode must be ready or pzstudio."
    exit 1
    ;;
esac

python3 "$tools_dir/stage.py" stage "$workshop_dir" "$RUNNER_TEMP/workshop-package" "$WORKSHOP_ID"
