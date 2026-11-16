set shell := ["bash", "-euo", "pipefail", "-c"]
export UV_NO_SYNC := "1"
export PYTHONPATH := justfile_directory() / "backend/src"

# List source and CI commands.
default:
    @just --list

# Prepare frozen dependencies and source metadata without starting a service.
setup:
    bun run install:all

# Run all build-free checks against prepared source and dependencies.
check:
    just --fmt --check
    bun run check

# Run the retained frontend/backend suites in an admitted prepared environment.
test:
    bun run test

# Build the existing frontend and backend package on CI.
build:
    bun run build

# Run every original native CI stage with owned fixture cleanup.
verify:
    bash scripts/ci/verify.sh

# Entry point for the shared recipe workflow.
[group("ci")]
ci-source: verify
