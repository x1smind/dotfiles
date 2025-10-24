# Work profile: environment variables, PATHs, aliases
export DOTFILES_PROFILE=work
export WORKSPACE_DIR="$HOME/work"
mkdir -p "$WORKSPACE_DIR" >/dev/null 2>&1 || true

# Example: language/tooling versions
# export PYENV_VERSION=3.12.6
# export RBENV_VERSION=3.3.5

# Git overrides
profile_git="$HOME/.gitconfig.work"
profile_git_helper="${DOTFILES_ROOT:-$HOME/.dotfiles}/bin/profile-git"
if [[ -x "$profile_git_helper" ]]; then
  work_git_email="${WORK_GIT_EMAIL:-you@work.example}"
  work_git_name="${WORK_GIT_NAME:-}"
  work_git_sign="${WORK_GIT_SIGN:-true}"
  profile_args=(--file "$profile_git" --email "$work_git_email")
  if [[ -n "$work_git_name" ]]; then
    profile_args+=(--name "$work_git_name")
  fi
  if [[ "$work_git_sign" == "true" ]]; then
    profile_args+=(--sign)
  else
    profile_args+=(--no-sign)
  fi
  "$profile_git_helper" "${profile_args[@]}"
fi
unset profile_git_helper work_git_email work_git_name work_git_sign profile_args
