# Personal profile
export DOTFILES_PROFILE=personal
export PERSONAL_DIR="$HOME/personal"
mkdir -p "$PERSONAL_DIR" >/dev/null 2>&1 || true

profile_git="$HOME/.gitconfig.personal"

profile_git_helper="${DOTFILES_ROOT:-$HOME/.dotfiles}/bin/profile-git"
if [[ -x "$profile_git_helper" ]]; then
  personal_git_email="${PERSONAL_GIT_EMAIL:-you@personal.example}"
  personal_git_name="${PERSONAL_GIT_NAME:-}"
  profile_args=(--file "$profile_git" --email "$personal_git_email")
  if [[ -n "$personal_git_name" ]]; then
    profile_args+=(--name "$personal_git_name")
  fi
  "$profile_git_helper" "${profile_args[@]}"
fi
unset profile_git_helper personal_git_email personal_git_name profile_args
