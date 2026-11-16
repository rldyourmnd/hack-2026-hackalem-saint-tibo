#!/usr/bin/env bash
# Full CI owns only a fresh GitHub checkout and its unique Compose fixture.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo_root"
[[ "${GITHUB_ACTIONS:-}" == true ]]
[[ "${GITHUB_RUN_ID:-}" =~ ^[0-9]+$ ]]
[[ "${GITHUB_RUN_ATTEMPT:-}" =~ ^[0-9]+$ ]]
[[ "${GITHUB_WORKSPACE:-}" == "$repo_root" ]]
[[ ! -e .env && ! -L .env ]]
export COMPOSE_PROJECT_NAME="saint-tibo-ci-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
# Bind uv to the SDK interpreter selected by the caller, not a cached minor-line guess.
export UV_PYTHON
UV_PYTHON=$(command -v python3)
cleanup() {
    local status=$? cleanup_status=0
    trap - EXIT
    docker compose down -v || cleanup_status=$?
    if ((status != 0)); then exit "$status"; fi
    exit "$cleanup_status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
bun run setup
just check
just test
just build
bun run test:integration
bun run api:generate
changed=$(git status --porcelain -- contracts/openapi.json frontend/src/shared/api/generated)
if [[ -n "$changed" ]]; then
    printf 'Generated API files changed:\n%s\n' "$changed" >&2
    exit 1
fi
docker build -t saint-tibo-backend:ci backend
