#!/usr/bin/env bash
set -euo pipefail

TARGET_UID="${HOST_UID:-1000}"
TARGET_GID="${HOST_GID:-1000}"
TARGET_USER="${DEV_USER:-dev}"
TARGET_HOME="${DEV_HOME:-/home/${TARGET_USER}}"

HAS_GOSU=0
if command -v gosu >/dev/null 2>&1; then
  HAS_GOSU=1
fi

mkdir -p /host-home

create_runtime_user() {
  if ! getent group "${TARGET_GID}" >/dev/null 2>&1; then
    groupadd --gid "${TARGET_GID}" "${TARGET_USER}" >/dev/null 2>&1 || true
  fi

  if id "${TARGET_USER}" >/dev/null 2>&1; then
    usermod --uid "${TARGET_UID}" --gid "${TARGET_GID}" "${TARGET_USER}" >/dev/null 2>&1 || true
  else
    useradd --uid "${TARGET_UID}" --gid "${TARGET_GID}" --create-home --shell /bin/bash "${TARGET_USER}"
  fi

  mkdir -p "${TARGET_HOME}"
}

sanitize_ssh_config() {
  local host_config="/host-home/.ssh/config"
  local dest_dir="${TARGET_HOME}/.ssh"
  local sanitized="${dest_dir}/config_linux"

  mkdir -p "${dest_dir}"
  chmod 700 "${dest_dir}"

  if [[ -f "${host_config}" ]]; then
    grep -Ev '^\s*(AddKeysToAgent|UseKeychain|IdentityFile|IdentitiesOnly)\b' "${host_config}" >"${sanitized}.tmp" || true
    mv "${sanitized}.tmp" "${sanitized}"
    chmod 600 "${sanitized}"
    ln -sfn "config_linux" "${dest_dir}/config"
  fi

  if [[ -f /host-home/.ssh/known_hosts ]]; then
    cp /host-home/.ssh/known_hosts "${dest_dir}/known_hosts"
    chmod 600 "${dest_dir}/known_hosts"
  fi

}

prepare_user_home() {
  mkdir -p "${TARGET_HOME}/.config"
  mkdir -p "${TARGET_HOME}/.cache"

  if [[ -f /host-home/.gitconfig ]]; then
    ln -sfn /host-home/.gitconfig "${TARGET_HOME}/.gitconfig"
  fi
  if [[ -d /host-home/.config/git ]]; then
    ln -sfn /host-home/.config/git "${TARGET_HOME}/.config/git"
  fi
  if [[ -d /host-home/.config/gh ]]; then
    ln -sfn /host-home/.config/gh "${TARGET_HOME}/.config/gh"
  fi
  if [[ -d /host-home/.codex ]]; then
    ln -sfn /host-home/.codex "${TARGET_HOME}/.codex"
  fi

  sanitize_ssh_config

}

configure_git() {
  if command -v git >/dev/null 2>&1; then
    if (( HAS_GOSU )); then
      gosu "${TARGET_USER}" git config --global --add safe.directory /workspace >/dev/null 2>&1 || true
    else
      git config --global --add safe.directory /workspace >/dev/null 2>&1 || true
    fi
  fi
}

configure_gh() {
  if command -v gh >/dev/null 2>&1 && [[ -d "${TARGET_HOME}/.config/gh" ]]; then
    chmod -R go= "${TARGET_HOME}/.config/gh" || true
  fi
}

configure_docker_access() {
  local sock="/var/run/docker.sock"
  if [[ -S "${sock}" ]]; then
    local sock_gid
    sock_gid="$(stat -c '%g' "${sock}" 2>/dev/null || echo '')"
    if [[ -n "${sock_gid}" ]]; then
      groupadd --non-unique --gid "${sock_gid}" docker-host >/dev/null 2>&1 || true
      local group_name
      group_name="$(getent group "${sock_gid}" | cut -d: -f1 || true)"
      if [[ -n "${group_name}" ]]; then
        usermod -a -G "${group_name}" "${TARGET_USER}" >/dev/null 2>&1 || true
      fi
    fi
  fi
}

setup_ssh_agent() {
  if [[ -n "${SSH_AUTH_SOCK:-}" ]] && [[ -S "${SSH_AUTH_SOCK}" ]]; then
    export SSH_AUTH_SOCK
    return
  fi
  if [[ -S /ssh-agent ]]; then
    export SSH_AUTH_SOCK=/ssh-agent
  fi
}

create_runtime_user
prepare_user_home
configure_git
configure_gh
configure_docker_access
setup_ssh_agent

export HOME="${TARGET_HOME}"
export USER="${TARGET_USER}"

if (( HAS_GOSU )); then
  exec gosu "${TARGET_USER}" "$@"
fi

printf 'gosu missing, running command as root\n' >&2
exec "$@"
