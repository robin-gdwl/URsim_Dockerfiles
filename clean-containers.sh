#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or is not on PATH." >&2
  exit 1
fi

containers="$(docker ps --all --quiet)"

if [[ -z "$containers" ]]; then
  echo "No Docker containers to remove."
  exit 0
fi

echo "Removing all Docker containers..."
docker rm --force $containers
echo "Removed all Docker containers. Docker images were not removed."
