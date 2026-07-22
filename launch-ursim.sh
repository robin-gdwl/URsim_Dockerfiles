#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 ROBOT_MODEL"
  echo
  echo "Examples:"
  echo "  $0 UR10"
  echo "  $0 UR5e"
  echo "  $0 UR20"
}

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or is not on PATH." >&2
  exit 1
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$#" -ne 1 ]]; then
  usage >&2
  exit 1
fi

robot_model="$1"
robot_model_key="$(printf '%s' "$robot_model" | tr '[:lower:]' '[:upper:]')"

case "$robot_model_key" in
  UR3 | UR5 | UR10)
    image="ursim/cb3:ssh"
    ;;
  UR3E | UR5E | UR10E | UR16E | UR20 | UR30)
    image="ursim/e-series:ssh"
    ;;
  *)
    echo "Error: unsupported robot model '$robot_model'." >&2
    echo "Supported CB3 models: UR3, UR5, UR10" >&2
    echo "Supported e-Series models: UR3e, UR5e, UR10e, UR16e, UR20, UR30" >&2
    exit 1
    ;;
esac

URSIM_HOME="${URSIM_HOME:-${HOME}/.ursim}"
PROGRAMS_DIR="${URSIM_HOME}/programs"
URCAPS_DIR="${URSIM_HOME}/urcaps"
SSH_PORT="${SSH_PORT:-2223}"

mkdir -p "$PROGRAMS_DIR" "$URCAPS_DIR"

if ! docker image inspect "$image" >/dev/null 2>&1; then
  echo "Error: Docker image '$image' was not found." >&2
  echo "Run ./build-images.sh first to build the SSH-enabled URSim images." >&2
  exit 1
fi

echo "Starting ${robot_model} with ${image}..."

exec docker run --rm -it \
  -e "ROBOT_MODEL=${robot_model}" \
  -p "${SSH_PORT}:22" \
  -p 29999:29999 \
  -p 30001:30001 \
  -p 30002:30002 \
  -p 30003:30003 \
  -p 30004:30004 \
  -p 30011:30011 \
  -p 30012:30012 \
  -p 30013:30013 \
  -p 5900:5900 \
  -p 6080:6080 \
  -v "${URCAPS_DIR}:/urcaps" \
  -v "${PROGRAMS_DIR}:/ursim/programs" \
  "$image"
