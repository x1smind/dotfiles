# Personal profile
export DOTFILES_PROFILE=personal
export PERSONAL_DIR="$HOME/personal"
mkdir -p "$PERSONAL_DIR" >/dev/null 2>&1 || true

profile_git="$HOME/.gitconfig.personal"
if [[ ! -f "$profile_git" ]]; then
  cat <<'EOT' > "$profile_git"
[user]
    email = you@personal.example
[commit]
    gpgsign = false
EOT
fi
