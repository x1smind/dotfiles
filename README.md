# Dotfiles

Cross‑platform dotfiles + bootstrap for **macOS** and **Linux (Debian/Ubuntu family | Fedora/Redhat)**.

- Shell: zsh + oh‑my‑zsh + **powerlevel10k**
- Fonts: **Hack Nerd Font** (primary) and Meslo Nerd (secondary)
- Managers: **nvm**, **pyenv**, **rbenv**
- Editors: **Neovim (LazyVim layout)**, `.vimrc` for vim compatibility
- Tmux: `.tmux.conf` with TPM bootstrap
- Per‑profile overrides: **work** / **personal**
- Per‑host overrides
- SSH & GPG bootstrap helpers

## One‑shot install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/x1smind/dotfiles/main/bin/bootstrap)"
```

Or locally:

```bash
git clone https://github.com/x1smind/dotfiles ~/.dotfiles
~/.dotfiles/bin/bootstrap
```

## Profiles

Select with `DOTFILES_PROFILE` env var or interactive prompt on first run:
- `work`
- `personal`

## Host overrides

Put extra snippets under `hosts/$(hostname)/` and they will be sourced automatically.
