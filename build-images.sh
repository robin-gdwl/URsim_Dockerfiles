#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or is not on PATH." >&2
  exit 1
fi

URCAP_VERSION="${URCAP_VERSION:-1.0.5}"
URSIM_HOME="${URSIM_HOME:-${HOME}/.ursim}"
PROGRAMS_DIR="${URSIM_HOME}/programs"
URCAPS_DIR="${URSIM_HOME}/urcaps"
URCAP_JAR="${URCAPS_DIR}/externalcontrol-${URCAP_VERSION}.jar"

download() {
  url="$1"
  output="$2"

  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --output "$output" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget --output-document="$output" "$url"
  else
    echo "Error: curl or wget is required to download '$output'." >&2
    exit 1
  fi
}

mkdir -p "$PROGRAMS_DIR" "$URCAPS_DIR"

if [[ ! -f "$URCAP_JAR" ]]; then
  echo "Downloading externalcontrol-${URCAP_VERSION}.jar..."
  download \
    "https://github.com/UniversalRobots/Universal_Robots_ExternalControl_URCap/releases/download/v${URCAP_VERSION}/externalcontrol-${URCAP_VERSION}.jar" \
    "$URCAP_JAR"
fi

docker_images=(
  "universalrobots/ursim_cb3"
  "universalrobots/ursim_e-series"
  "universalrobots/ursim_polyscopex"
)

for image in "${docker_images[@]}"; do
  echo "Pulling ${image}..."
  docker pull "$image"
done

echo "Prepared URSim images and External Control folders:"
echo "  Programs: ${PROGRAMS_DIR}"
echo "  URCaps:   ${URCAPS_DIR}"
