# Homebrew (macOS)
if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi

# Local bins
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
