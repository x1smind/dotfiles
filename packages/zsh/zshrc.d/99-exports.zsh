export PIP_REQUIRE_VIRTUALENV=false
# Add your API keys via a .secrets.zsh that you DO NOT commit:
[ -r "$HOME/.secrets.zsh" ] && source "$HOME/.secrets.zsh"
# Profile selection
export DOTFILES_PROFILE=${DOTFILES_PROFILE:-}
