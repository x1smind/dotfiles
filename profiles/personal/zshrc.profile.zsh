# Personal profile
export DOTFILES_PROFILE=personal
export PERSONAL_DIR="$HOME/personal"
mkdir -p "$PERSONAL_DIR" >/dev/null 2>&1 || true

cat > "$HOME/.gitconfig.personal" <<'EOF'
[user]
    email = you@personal.example
[commit]
    gpgsign = false
EOF
