#!/usr/bin/env bash
set -euo pipefail

HOST_UID=${HOST_UID:-1000}
HOST_GID=${HOST_GID:-1000}
HOME_OVERRIDE=${HOME_OVERRIDE:-/workspace/.home}
DEFAULT_USER=${DEV_USER:-dev}
DEFAULT_GROUP=${DEV_GROUP:-$DEFAULT_USER}
DEFAULT_SHELL=${DEV_SHELL:-/bin/bash}

lookup_group() {
  local gid="$1"
  getent group "$gid" | cut -d: -f1 || true
}

lookup_user() {
  local uid="$1"
  getent passwd "$uid" | cut -d: -f1 || true
}

ensure_primary_group() {
  local gid="$1"
  local fallback="${2:-dev}"
  local name
  name="$(lookup_group "$gid")"
  if [[ -n "$name" ]]; then
    echo "$name"
    return
  fi

  groupadd --non-unique --gid "$gid" "$fallback" >/dev/null 2>&1 || true
  name="$(lookup_group "$gid")"
  echo "${name:-$fallback}"
}

ensure_user() {
  local uid="$1"
  local gid="$2"
  local fallback="${3:-dev}"
  local name
  name="$(lookup_user "$uid")"
  if [[ -n "$name" ]]; then
    usermod --uid "$uid" --gid "$gid" --shell "$DEFAULT_SHELL" "$name" >/dev/null 2>&1 || true
    echo "$name"
    return
  fi

  if id "$fallback" >/dev/null 2>&1; then
    usermod --uid "$uid" --gid "$gid" --shell "$DEFAULT_SHELL" "$fallback" >/dev/null 2>&1 || true
    echo "$fallback"
    return
  fi

  useradd --no-create-home --uid "$uid" --gid "$gid" --shell "$DEFAULT_SHELL" "$fallback" >/dev/null 2>&1 || true
  name="$(lookup_user "$uid")"
  echo "${name:-$fallback}"
}

HAS_GOSU=0
if command -v gosu >/dev/null 2>&1; then
  HAS_GOSU=1
fi

group_name="$(ensure_primary_group "$HOST_GID" "$DEFAULT_GROUP")"
group_name="${group_name:-$DEFAULT_GROUP}"

user_name="$(ensure_user "$HOST_UID" "$HOST_GID" "$DEFAULT_USER")"
user_name="${user_name:-$DEFAULT_USER}"

if getent group sudo >/dev/null 2>&1; then
  usermod -a -G sudo "$user_name" >/dev/null 2>&1 || true
fi

configure_docker_access() {
  local user="$1"
  local sock="/var/run/docker.sock"
  if [[ ! -S "$sock" ]]; then
    return
  fi
  local sock_gid
  sock_gid="$(stat -c '%g' "$sock" 2>/dev/null || true)"
  if [[ -z "$sock_gid" ]]; then
    return
  fi
  local docker_group
  docker_group="$(lookup_group "$sock_gid")"
  if [[ -z "$docker_group" ]]; then
    docker_group="docker-host"
    groupadd --non-unique --gid "$sock_gid" "$docker_group" >/dev/null 2>&1 || true
    docker_group="$(lookup_group "$sock_gid")"
  fi
  if [[ -n "$docker_group" ]]; then
    usermod -a -G "$docker_group" "$user" >/dev/null 2>&1 || true
  fi
}

configure_docker_access "$user_name"

prepare_home() {
  local home_dir="$1"
  mkdir -p "$home_dir"
  chown "$HOST_UID:$HOST_GID" "$home_dir" >/dev/null 2>&1 || true
  mkdir -p "$home_dir/.ssh"
  chmod 700 "$home_dir/.ssh" >/dev/null 2>&1 || true
  chown "$HOST_UID:$HOST_GID" "$home_dir/.ssh" >/dev/null 2>&1 || true
}

prepare_home "$HOME_OVERRIDE"

if [[ -S /ssh-agent ]]; then
  chmod 666 /ssh-agent >/dev/null 2>&1 || true
fi

configure_git_safe() {
  if ! command -v git >/dev/null 2>&1; then
    return
  fi
  local target_dir="/workspace/dotfiles"
  if ((HAS_GOSU)); then
    gosu "$user_name:$group_name" git config --global --add safe.directory "$target_dir" >/dev/null 2>&1 || true
  else
    git config --global --add safe.directory "$target_dir" >/dev/null 2>&1 || true
  fi
}

configure_git_safe

export HOME="$HOME_OVERRIDE"
export USER="$user_name"
export TERM="${TERM:-xterm-256color}"
export COLORTERM="${COLORTERM:-truecolor}"

if ((HAS_GOSU)); then
  exec gosu "$user_name:$group_name" "$@"
fi

printf 'gosu missing, running command as root\n' >&2
exec "$@"
