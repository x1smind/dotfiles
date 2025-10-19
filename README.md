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

### Safe dry-run

Never test against your real `$HOME`. Point the bootstrapper at a temp directory and enable dry-run mode:

```bash
export DOTFILES_TARGET="$(mktemp -d)"
export DOTFILES_PROFILE=personal
~/.dotfiles/bin/bootstrap --dry-run --target "$DOTFILES_TARGET"
```

## Testing

### Docker smoke tests

Use the Docker harness to exercise the one-shot installer inside disposable Ubuntu and Fedora containers:

```bash
make docker-build            # build/update the container images (auto-pulls bases)
make docker-dry              # run bootstrap --dry-run against a temp $HOME
make docker-install          # run the real installer against a temp $HOME (backs up bootstrap-created dotfiles before linking)
make docker-down             # stop containers when finished
```

Docker Desktop (or an equivalent daemon) must be running; these targets now fail-fast with a friendly message if the socket is unavailable.

Override the profile per run with `DOTFILES_PROFILE=work make docker-dry`.

The first `make docker-install` run installs extra build dependencies (liblzma, libyaml, etc.) and compiles Python & Ruby, so expect several minutes on a cold container.

GitHub Actions runs the same `docker-build`, `docker-dry`, and `docker-install` targets (see `.github/workflows/docker-smoke.yml`) to keep the one-shot installer green on Ubuntu and Fedora. A dedicated macOS runner (`.github/workflows/macos-smoke.yml`) executes the stub harness on PRs targeting `main`/`release/**` and performs a weekly macOS 14 dry-run of `bin/bootstrap`.

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

## Releases

The current release is **v0.3.0**. See [CHANGELOG.md](CHANGELOG.md) for a complete history.
