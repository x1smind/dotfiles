#!/usr/bin/env bash
set -euo pipefail

HOST_UID=${HOST_UID:-1000}
HOST_GID=${HOST_GID:-1000}
HOME_OVERRIDE=${HOME_OVERRIDE:-/workspace/.home}
DEFAULT_USER=${DEV_USER:-dev}
DEFAULT_GROUP=${DEV_USER:-dev}

lookup_group() {
  local gid="$1"
  getent group "$gid" | cut -d: -f1 || true
}

lookup_user() {
  local uid="$1"
  getent passwd "$uid" | cut -d: -f1 || true
}

group_name=$(lookup_group "$HOST_GID")
if [[ -z "$group_name" ]]; then
  group_name="$DEFAULT_GROUP"
  groupadd --non-unique --gid "$HOST_GID" "$group_name" >/dev/null 2>&1 || group_name=$(lookup_group "$HOST_GID")
fi
if [[ -z "$group_name" ]]; then
  group_name="$DEFAULT_GROUP"
fi

user_name=$(lookup_user "$HOST_UID")
if [[ -z "$user_name" ]]; then
  user_name="$DEFAULT_USER"
  useradd --no-create-home --gid "$HOST_GID" --uid "$HOST_UID" --shell /bin/bash "$user_name" >/dev/null 2>&1 || user_name=$(lookup_user "$HOST_UID")
fi
if [[ -z "$user_name" ]]; then
  user_name="$DEFAULT_USER"
fi

export HOME="$HOME_OVERRIDE"

mkdir -p "$HOME"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh" >/dev/null 2>&1 || true

if [[ -S /ssh-agent ]]; then
  chmod 666 /ssh-agent >/dev/null 2>&1 || true
fi

if command -v git >/dev/null 2>&1; then
  gosu "$user_name:$group_name" git config --global --add safe.directory /workspace/dotfiles >/dev/null 2>&1 || true
fi

exec gosu "$user_name:$group_name" "$@"
