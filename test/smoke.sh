#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

created_target=0
if [[ -z "${DOTFILES_TARGET:-}" ]]; then
  DOTFILES_TARGET="$(mktemp -d)"
  created_target=1
fi

cleanup() {
  if (( created_target )); then
    rm -rf "$DOTFILES_TARGET"
  fi
}
trap cleanup EXIT

echo ">> Using DOTFILES_TARGET=$DOTFILES_TARGET"

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
