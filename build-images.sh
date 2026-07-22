#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or is not on PATH." >&2
  exit 1
fi

usage() {
  echo "Usage: $0 [--with-polyscopex]"
  echo
  echo "By default, this builds SSH-enabled CB3 and e-Series URSim images."
}

include_polyscopex=0

for arg in "$@"; do
  case "$arg" in
    --with-polyscopex)
      include_polyscopex=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      echo "Error: unknown option '$arg'." >&2
      exit 1
      ;;
  esac
done

URCAP_VERSION="${URCAP_VERSION:-1.0.5}"
SSH_ROOT_PASSWORD="${SSH_ROOT_PASSWORD:-easybot}"
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

BUILD_CONTEXT="$(mktemp -d)"
trap 'rm -rf "$BUILD_CONTEXT"' EXIT

mkdir -p "${BUILD_CONTEXT}/programs"
cp "$URCAP_JAR" "${BUILD_CONTEXT}/externalcontrol-${URCAP_VERSION}.jar"

if [[ -d programs ]]; then
  cp -R programs/. "${BUILD_CONTEXT}/programs/"
fi

docker_builds=(
  "ursim/cb3:ssh:Dockerfile.ursim-cb3"
  "ursim/e-series:ssh:Dockerfile.ursim-e-series"
)

if [[ "$include_polyscopex" -eq 1 ]]; then
  docker_builds+=("ursim/polyscopex:ssh:Dockerfile.ursim-polyscopex")
fi

for build in "${docker_builds[@]}"; do
  image="${build%:*}"
  dockerfile="${build##*:}"

  echo "Building ${image} from ${dockerfile}..."
  cp "$dockerfile" "${BUILD_CONTEXT}/Dockerfile"
  docker build \
    --pull \
    --build-arg "URCAP_VERSION=${URCAP_VERSION}" \
    --build-arg "SSH_ROOT_PASSWORD=${SSH_ROOT_PASSWORD}" \
    --tag "$image" \
    "$BUILD_CONTEXT"
done

echo "Prepared SSH-enabled URSim images and External Control folders:"
echo "  Programs: ${PROGRAMS_DIR}"
echo "  URCaps:   ${URCAPS_DIR}"
