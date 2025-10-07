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
bin/bootstrap --dry-run --target "$DOTFILES_TARGET"
```

### Quick edit loop

* Make changes under `packages/*` or `profiles/*`.
* Use `stow -d packages -t "$DOTFILES_TARGET" <package>` to check link plans.
* Add minimal fixtures to `test/` when behavior changes.

---

## Commit & PR guidelines

* **Branch naming**: `feat/<area>-<topic>`, `fix/<area>-<topic>`, `chore/…`
* **Conventional commits** (recommended): `feat(zsh): add autosuggestions`
* **One concern per PR**; keep diffs readable.
* **Describe OS coverage**: where you tested (macOS, Ubuntu, Fedora).
* **Add/Update tests** in `test/` for new logic or flags.

---

## Checks (run before PR)

```bash
# 1) Static checks
command -v shellcheck >/dev/null && shellcheck bin/* packages/**/*.sh 2>/dev/null || true
command -v shfmt >/dev/null && shfmt -d . || true

# 2) Bootstrap dry-run into temp HOME
export DOTFILES_TARGET="$(mktemp -d)"
bin/bootstrap --dry-run --target "$DOTFILES_TARGET"

# 3) Stow simulation
stow -n -v -d packages -t "$DOTFILES_TARGET" $(ls packages) || true

# 4) Minimal cross-distro smoke tests (containers if available)
test/smoke.sh   # see test/ for examples

# 5) Neovim health (optional)
nvim --headless "+Lazy! sync" "+qall" || true
```

> PRs that add runtime-modifying scripts **must** support `--dry-run`.

---

## Cross-platform notes

* **macOS**: prefer Homebrew taps; gate logic with `uname` checks.
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
