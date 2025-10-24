# Dotfiles

Cross‑platform dotfiles + bootstrap for **macOS** and **Linux (Debian/Ubuntu family | Fedora/Redhat)**.

- Shell: zsh + oh‑my‑zsh + **powerlevel10k**
- Fonts: **Hack Nerd Font** (primary) and Meslo Nerd (secondary)
- Managers: **nvm**, **pyenv**, **rbenv**
- Editors: **Neovim 0.11.4 (Lazy.nvim layout)**, `.vimrc` for vim compatibility
- Tmux: `.tmux.conf` with TPM bootstrap
- Per‑profile overrides: **work** / **personal**
- Per‑host overrides
- SSH & GPG bootstrap helpers

## Requirements

- Administrator privileges (sudo rights) so the bootstrapper can install GNU Stow and other prerequisites when needed.

## One‑shot install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/x1smind/dotfiles/main/bin/bootstrap)"
```

> Prerequisite: install `curl` first (e.g., `sudo apt-get install -y curl` on Debian/Ubuntu).

Or locally:

```bash
git clone https://github.com/x1smind/dotfiles ~/.dotfiles
~/.dotfiles/bin/bootstrap
```

When run from an interactive terminal, the bootstrapper now offers a short wizard to choose your profile (`work` or `personal`) and toggle optional language managers (`nvm`, `pyenv`, `rbenv`). Set `DOTFILES_PROFILE`/`DOTFILES_FEATURES` or pass `--no-prompt` to skip the questions (CI, scripts, or unattended installs).

### Safe dry-run

Never test against your real `$HOME`. Point the bootstrapper at a temp directory and enable dry-run mode:

```bash
export DOTFILES_TARGET="$(mktemp -d)"
export DOTFILES_PROFILE=personal
~/.dotfiles/bin/bootstrap --no-prompt --dry-run --target "$DOTFILES_TARGET"
```

## Testing

### Docker smoke tests

Use the Docker harness to exercise the one-shot installer inside disposable Ubuntu and Fedora containers:

```bash
make docker-build            # build/update the container images (auto-pulls bases)
make docker-dry              # run bootstrap --dry-run against a temp $HOME
make docker-smoke            # same as docker-dry but also exercises stdin bootstrap mode
make docker-install          # run the real installer against a temp $HOME (backs up bootstrap-created dotfiles before linking)
make docker-down             # stop containers when finished
```

Docker Desktop (or an equivalent daemon) must be running; these targets now fail-fast with a friendly message if the socket is unavailable.

Override the profile per run with `DOTFILES_PROFILE=work make docker-dry`.

Use `docker-smoke` when you need the extra stdin coverage; CI defaults to `docker-dry` for speed and `docker-install` for full installs.

The first `make docker-install` run installs extra build dependencies (liblzma, libyaml, etc.) and compiles Python & Ruby, so expect several minutes on a cold container.

GitHub Actions runs the same `docker-build`, `docker-dry`, and `docker-install` targets (see `.github/workflows/docker-smoke.yml`) to keep the one-shot installer green on Ubuntu and Fedora. A dedicated macOS runner (`.github/workflows/macos-smoke.yml`) executes the stub harness on PRs targeting `main`/`release/**` and performs a weekly macOS 14 dry-run of `bin/bootstrap`. CI reuses BuildKit caches per distro (`docker-smoke-ubuntu`, `docker-smoke-fedora`), so repeat runs stay fast; touch the corresponding `docker/Dockerfile.*` or bump a cache busting ARG when you need a fresh image.

### macOS bootstrap checks

Run the macOS bootstrap logic in a Linux/macOS-agnostic way using the stub harness:

```bash
make test-brew               # simulate macOS bootstrap with stubbed Homebrew
./test/macos.sh real         # (macOS only) run bin/bootstrap --dry-run against a temp HOME
```

### Repo layout

```
packages/           # stow packages (git/, zsh/, nvim/, tmux/, vim/, …)
profiles/<name>/    # profile overlays: work/, personal/
hosts/<hostname>/   # host overrides, highest precedence
bin/                # bootstrap & helper scripts
```

## Profiles

Select with `DOTFILES_PROFILE` env var or interactive prompt on first run:
- `work`
- `personal`

Each profile scaffolds a dedicated git include (e.g. `~/.gitconfig.work`) via `bin/profile-git`. Override the seeded metadata with `WORK_GIT_EMAIL` / `PERSONAL_GIT_EMAIL` (and optional `*_GIT_NAME`) before launching the shell, or edit the generated file after the first run. Work profiles enable commit signing by default; set `WORK_GIT_SIGN=false` if your host should skip it.

### SSH & GPG helpers

Run `~/.dotfiles/bin/keys-setup` after bootstrapping to generate SSH and GPG keys (or export existing ones). The script prints the public material and links to the GitHub settings screens so you can register the credentials immediately.

## Feature toggles

Control optional installers with the `DOTFILES_FEATURES` environment variable (comma-separated).  
Default: `core,nvm,pyenv,rbenv`.

Examples:

```bash
# Skip language runtimes when testing in containers
DOTFILES_FEATURES=core bin/bootstrap --dry-run --target "$DOTFILES_TARGET"

# Only install nvm alongside the core dotfiles
DOTFILES_FEATURES=core,nvm bin/bootstrap --target "$HOME"
```

## Host overrides

Put extra snippets under `hosts/$(hostname)/` and they will be sourced automatically.

## Rollback guide

The bootstrapper backs up or installs everything in predictable locations, so you can undo changes if a run fails midway.

1. **Restore archived dotfiles** – Conflicting originals are moved to `~/.dotfiles/.bootstrap-backups/<timestamp>/`. Copy what you need back into `$HOME`.
2. **Remove Stow links** – If symlinks were created, run `cd ~/.dotfiles && stow -D git nvim tmux vim zsh` (adjust the package list as needed).
3. **Clean loader snippets** – Remove any `source "~/.dotfiles/..."` lines appended to `~/.zprofile`, `~/.zshrc.local`, or `~/.gitconfig.local`.
4. **Optional tool cleanup** – Delete tool managers if you want a pristine state: `rm -rf ~/.oh-my-zsh ~/.tmux/plugins/tpm ~/.nvm ~/.pyenv ~/.rbenv`.
5. **Remove the repo clone** – If you no longer want it, `rm -rf ~/.dotfiles`.

Running `~/.dotfiles/bin/bootstrap --dry-run --target "$(mktemp -d)" --profile personal` shows what would run without touching your real home; it’s handy to double-check the current state before trying again.

## Migration notes

### 2025-10-07

* All stowable configs now live under `packages/*`.
  Update automation to call `stow -d packages`.
* `bin/bootstrap` gained `--dry-run`, `--target`, and `--profile` flags; update scripts and CI jobs accordingly.
* Use `test/smoke.sh` to validate stow link plans against a disposable `$DOTFILES_TARGET`.

### 2025-10-16

* The top-level `Brewfile` has been moved to `macos/Brewfile`.
* Update any local scripts or aliases to:

  ```bash
  brew bundle --file=macos/Brewfile
  ```
* Remove any stale lockfile:

  ```bash
  rm -f Brewfile.lock.json
  ```
* If using Make targets (`make brew` or `make bootstrap`), no action is needed — they already reference `macos/Brewfile`.

### 2025-10-20

* Bootstrap downloads Neovim 0.11.4 tarballs (Linux/macOS) and ships a Lazy.nvim config with neo-tree v3, Telescope fzf-native, and new colorschemes.
* macOS flow prompts for missing Xcode Command Line Tools and surfaces guidance when Homebrew locks aren’t writable.
* Existing pyenv/rbenv installs and global `git config` identity are reused instead of overwritten.
* README now documents rollback steps and zsh aliases/dev-shell defaults were refreshed.

## Releases

The current release is **v0.5.0**. See [CHANGELOG.md](CHANGELOG.md) for a complete history.
