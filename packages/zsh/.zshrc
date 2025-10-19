# Oh My Zsh core
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

# Load oh-my-zsh if installed
if [ -s "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# Load modular pieces
setopt null_glob 2>/dev/null
for rc_dir in "$HOME/.zshrc.d" "$HOME/zshrc.d"; do
  for f in "${rc_dir}"/*.zsh; do
    [ -r "$f" ] && source "$f"
  done
done
unsetopt null_glob 2>/dev/null

# Profile/host overrides
[ -r "$HOME/.profile.local" ] && source "$HOME/.profile.local"
[ -r "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
[ -r "$HOME/.gitconfig.local" ] && git config --global include.path "~/.gitconfig.local" >/dev/null 2>&1

# p10k (must be at the end)
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
