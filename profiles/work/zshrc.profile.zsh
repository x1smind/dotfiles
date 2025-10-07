# Work profile: environment variables, PATHs, aliases
export DOTFILES_PROFILE=work
export WORKSPACE_DIR="$HOME/work"
mkdir -p "$WORKSPACE_DIR" >/dev/null 2>&1 || true

# Example: language/tooling versions
# export PYENV_VERSION=3.12.6
# export RBENV_VERSION=3.3.5

# Git overrides
cat > "$HOME/.gitconfig.work" <<'EOF'
[user]
    email = you@work.example
[commit]
    gpgsign = true
EOF
