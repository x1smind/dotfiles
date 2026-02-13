# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Added by Antigravity
export PATH="/Users/x1smind/.antigravity/antigravity/bin:$PATH"
