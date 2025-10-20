#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  echo "Usage: $0 [dry|real] [--stdin]" >&2
}

MODE="${1:-dry}"
WITH_STDIN=0

case "$MODE" in
  dry | real) ;;
  *)
    usage
    exit 2
    ;;
esac

if [[ "${2:-}" == "--stdin" ]]; then
  WITH_STDIN=1
elif [[ -n "${2:-}" ]]; then
  usage
  exit 2
fi

if [[ "${SMOKE_INCLUDE_STDIN:-}" == "1" ]]; then
  WITH_STDIN=1
fi

created_target=0
if [[ -z "${DOTFILES_TARGET:-}" ]]; then
  DOTFILES_TARGET="$(mktemp -d)"
  created_target=1
fi

DOTFILES_PROFILE="${DOTFILES_PROFILE:-personal}"

cleanup() {
  if ((created_target)); then
    rm -rf "$DOTFILES_TARGET"
  fi
}
trap cleanup EXIT

echo ">> Mode: ${MODE}"
echo ">> Using DOTFILES_PROFILE=${DOTFILES_PROFILE}"
echo ">> Using DOTFILES_TARGET=${DOTFILES_TARGET}"

bootstrap_cmd=("${REPO_DIR}/bin/bootstrap" "--target" "${DOTFILES_TARGET}" "--profile" "${DOTFILES_PROFILE}")
if [[ "$MODE" == "dry" ]]; then
  bootstrap_cmd=("${REPO_DIR}/bin/bootstrap" "--dry-run" "--target" "${DOTFILES_TARGET}" "--profile" "${DOTFILES_PROFILE}")
fi

echo ">> Running ${bootstrap_cmd[*]}"
"${bootstrap_cmd[@]}"

if [[ "$MODE" == "dry" && $WITH_STDIN -eq 1 ]]; then
  echo ">> Running stdin bootstrap simulation"
  env DOTFILES_PROFILE="${DOTFILES_PROFILE}" \
    DOTFILES_TARGET="${DOTFILES_TARGET}" \
    REPO_DIR="${REPO_DIR}" \
    bash -s -- --dry-run --target "${DOTFILES_TARGET}" --profile "${DOTFILES_PROFILE}" <"${REPO_DIR}/bin/bootstrap"
fi

if [[ "$MODE" == "dry" ]]; then
  echo ">> Running minimal feature bootstrap (DOTFILES_FEATURES=core)"
  core_target="$(mktemp -d)"
  env DOTFILES_FEATURES=core \
    DOTFILES_TARGET="${core_target}" \
    DOTFILES_PROFILE="${DOTFILES_PROFILE}" \
    "${REPO_DIR}/bin/bootstrap" --dry-run --target "${core_target}" --profile "${DOTFILES_PROFILE}"
  rm -rf "${core_target}"
fi

if ! command -v stow >/dev/null 2>&1; then
  echo ">> stow not found; skipping link plan"
  exit 0
fi

mapfile -t packages < <(find "${REPO_DIR}/packages" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
if ((${#packages[@]} == 0)); then
  echo ">> No packages found under packages/"
  exit 0
fi

echo ">> Running stow -n -v -d ${REPO_DIR}/packages --target ${DOTFILES_TARGET} ${packages[*]}"
stow -n -v -d "${REPO_DIR}/packages" --target "${DOTFILES_TARGET}" "${packages[@]}"
