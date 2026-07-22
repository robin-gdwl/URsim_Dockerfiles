#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or is not on PATH." >&2
  exit 1
fi

missing=0
for path in externalcontrol-1.0.5.urcap programs; do
  if [[ ! -e "$path" ]]; then
    echo "Error: required build input '$path' is missing." >&2
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

images=(
  "ursim-cb3:Dockerfile.ursim-cb3"
  "ursim-e-series:Dockerfile.ursim-e-series"
  "ursim-polyscopex:Dockerfile.ursim-polyscopex"
)

for image in "${images[@]}"; do
  tag="${image%%:*}"
  dockerfile="${image#*:}"

  echo "Building ${tag} from ${dockerfile}..."
  docker build --pull --tag "$tag" --file "$dockerfile" .
done

echo "Built all URSim Docker images."
