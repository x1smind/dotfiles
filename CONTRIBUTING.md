# CONTRIBUTING.md

## TL;DR

* Fork → branch → small, focused PRs.
* Don’t write to `$HOME` in tests; use dry-runs & temp dirs.
* Keep cross-platform (macOS + Debian/Ubuntu + Fedora/RedHat) in mind.
* Prefer **Stow**-style layouts, idempotent scripts, and feature flags.
* Run the checks below before you open a PR.

---

## Project scope

Cross-platform dotfiles + bootstrap for macOS and Linux (Debian/Ubuntu family | Fedora/RedHat) with:

* zsh + oh-my-zsh + powerlevel10k
* Hack Nerd Font (primary) / Meslo Nerd (secondary)
* nvm / pyenv / rbenv
* Neovim (LazyVim layout) + `.vimrc` shim
* Tmux (+ TPM bootstrap)
* Profiles: `work`, `personal`; host overrides under `hosts/$(hostname)/`
* SSH & GPG bootstrap helpers

### Design principles

* **Symlink farm first**: keep real files in repo; link into `$HOME` via Stow.
* **Idempotent bootstrap**: running `bin/bootstrap` multiple times is safe.
* **No surprise writes**: support `--dry-run`, `DOTFILES_TARGET`, and temp homes.
* **Small modules**: per-tool subdirs, minimal cross-talk.
* **Feature gates**: optional installers toggle via `DOTFILES_FEATURES` (e.g., skip language runtimes in CI).
* **Degradations > failures**: if a tool isn’t available, skip gracefully.

---

## Repo layout (conventions)

```
.dotfiles/
  bin/                # bootstrap & helper scripts (POSIX sh if possible)
  packages/           # stow packages (git/, zsh/, nvim/, tmux/, etc.)
    git/.gitconfig
    zsh/.zshrc
    nvim/.config/nvim/...
  profiles/           # profile overlays: work/, personal/
  hosts/$(hostname)/  # host overlays (lowest precedence: base < profile < host)
  test/               # local test harness & fixtures
```

> Stow target is `$HOME` by default. Overlays: `packages/` (base) → `profiles/$DOTFILES_PROFILE/` → `hosts/$(hostname)/`.

---

## Getting started (dev)

```bash
git clone https://github.com/x1smind/dotfiles ~/.dotfiles
cd ~/.dotfiles
# never test against your real $HOME
export DOTFILES_TARGET="$(mktemp -d)"
export DOTFILES_PROFILE=personal
bin/bootstrap --no-prompt --dry-run --target "$DOTFILES_TARGET"
```

If you run the installer in an interactive terminal, it now walks through a short wizard (profile selection + optional `nvm`/`pyenv`/`rbenv`). Pre-set `DOTFILES_PROFILE`/`DOTFILES_FEATURES` or pass `--no-prompt` whenever you need a non-interactive run.

### Quick edit loop

* Make changes under `packages/*` or `profiles/*`.
* Use `stow -d packages -t "$DOTFILES_TARGET" <package>` to check link plans.
* Add minimal fixtures to `test/` when behavior changes.

### Docker harness

Exercise the one-shot installer in disposable Ubuntu and Fedora containers:

```bash
make docker-build            # build/update container images (base images auto-pull)
make docker-dry              # bootstrap --dry-run in each distro
make docker-smoke            # dry-run + stdin bootstrap coverage in each distro
make docker-install          # real install into temp $HOME (backs up conflicts; optional)
make docker-down             # stop containers when done
```

Ensure Docker Desktop (or another Docker daemon) is running first. These targets invoke `docker-ready`, which fails fast with a helpful message if the socket is unavailable.

Override the profile per run with `DOTFILES_PROFILE=work make docker-dry`.

Reach for `docker-smoke` when you want the stdin bootstrap coverage inside containers; CI defaults to `docker-dry` for speed and pairs it with `docker-install` for full runs.

CI builds reuse BuildKit caches scoped to each distro (`docker-smoke-ubuntu`, `docker-smoke-fedora`). Touch the matching `docker/Dockerfile.*` (or adjust a cache-busting ARG) when you need to invalidate the image layers in GitHub Actions.

Real-mode installs will back up any bootstrap-created dotfiles (e.g., Oh My Zsh templates) before linking and install extra build dependencies (liblzma, libyaml, etc.) so that pyenv/rbenv can compile toolchains; expect several minutes on the first run in a fresh container.

Need an interactive Linux shell that mirrors CI? Use `make docker-dev-shell`. Docker caches this image, so rebuild it after changing `docker/Dockerfile.dev` or `docker/dev-entrypoint.sh` with `docker compose -f docker/docker-compose.yml build --no-cache dev`. (The `make docker-build` target only touches the Ubuntu/Fedora smoke images.) GitHub and Codex configs are mounted read/write so you can refresh tokens inside the container—those updates persist back to the host.

> macOS note: if `gh auth status` reports an invalid token, re-auth inside the container with `gh auth login --web`. macOS stores the host token in the keychain, which isn’t readable inside Linux.

---

## Commit & PR guidelines

* **Branch naming**:  
  Use one of the following prefixes:  
  - `feat/<area>-<topic>` – new features or enhancements  
  - `fix/<area>-<topic>` – bug fixes or regressions  
  - `chore/<area>-<topic>` – refactors, CI, tooling, or maintenance tasks  
  - `docs/<area>-<topic>` – documentation-only changes  
  - `test/<area>-<topic>` – new or updated tests  
  - `refactor/<area>-<topic>` – structural changes without behavior changes  

* **Conventional commits** (recommended):  
  - `feat(zsh): add autosuggestions`  
  - `fix(fedora): install hostname package`  
  - `docs(agents|contributors): commit message convention`  
  - `chore(ci): extend matrix for Ubuntu + Fedora`  
  - `refactor(bootstrap): extract sanity check for missing commands`

* **One concern per PR**; keep diffs small and readable.  

* **Describe OS coverage**:  
  Always state where you tested (`macOS`, `Ubuntu`, `Fedora`, etc.).  

* **Add/Update tests** in `test/` for new logic or flags.  
* **CI awareness**: GitHub Actions runs Shellcheck and the Docker Smoke matrix (`ubuntu`, `fedora`). Verify `./test/smoke.sh dry` and `make docker-dry`/`make docker-install` locally before opening a PR. BuildKit caches keep the docker-smoke images warm; editing the matching `docker/Dockerfile.*` (or tweaking a cache-busting ARG) refreshes the layers automatically.

* **Note:** Agents auto-generate these commit messages when changes are staged.
  Human contributors should follow the same convention when committing manually.

---

## Checks (run before PR)

```bash
# 1) Static checks
command -v shellcheck >/dev/null && shellcheck bin/* packages/**/*.sh 2>/dev/null || true
command -v shfmt >/dev/null && shfmt -d . || true

# 2) Bootstrap dry-run into temp HOME
export DOTFILES_TARGET="$(mktemp -d)"
bin/bootstrap --dry-run --target "$DOTFILES_TARGET"

# 2b) Minimal feature dry-run (skip heavy runtimes)
DOTFILES_FEATURES=core bin/bootstrap --no-prompt --dry-run --target "$DOTFILES_TARGET"

# 3) Stow simulation
stow -n -v -d packages -t "$DOTFILES_TARGET" $(ls packages) || true

# 4) Quick smoke test (local environment)
./test/smoke.sh dry
# Optional: include stdin coverage
./test/smoke.sh dry --stdin

# 5) macOS bootstrap stubs (no mac required)
make test-brew

# 6) Minimal cross-distro smoke tests (containers if available)
make docker-build
make docker-dry
# Optional: include stdin coverage in containers
make docker-smoke
# run this when you need to validate the full install path (takes several minutes; backs up conflicts automatically)
make docker-install

# 7) Neovim health (optional)
nvim --headless "+Lazy! sync" "+qall" || true
```

> PRs that add runtime-modifying scripts **must** support `--dry-run`.

---

## Cross-platform notes

* **macOS**: prefer Homebrew taps; gate logic with `uname` checks. Use `macos/Brewfile` and keep `_brew_preflight` removing the deprecated `homebrew/cask-fonts` tap before `brew bundle`.
* **Debian/Ubuntu**: use `apt-get -y` and `DEBIAN_FRONTEND=noninteractive`.
* **Fedora/RedHat**: use `dnf -y`; avoid distro-specific flags unless gated.
* **Fonts**: install to `~/Library/Fonts` (macOS) or `~/.local/share/fonts` (Linux).
* **SSH/GPG**: never overwrite existing keys; prompt or back up first.

---

## Adding a new package (example)

1. Create `packages/fd/` with the files as they should appear in `$HOME`.
2. Add install logic (if any) to `bin/bootstrap` or `bin/install-fd.sh`.
3. Ensure dry-run works and Stow link plan looks clean.
4. Add a smoke test to `test/`.

---

## Security & privacy

* Do **not** commit secrets or private keys.
* Default configs should not weaken security (e.g., permissive SSH settings).
* If a change touches security-sensitive areas, include a short risk note.

---

## Issue labels (suggested)

* `area:zsh` `area:git` `area:nvim` `area:tmux` `area:bootstrap`
* `os:macos` `os:debian` `os:fedora`
* `type:feat` `type:fix` `type:refactor` `type:docs`
* `good first issue` `help wanted`

---

## Code of Conduct

Be respectful. No personal data or secrets in issues/PRs.
