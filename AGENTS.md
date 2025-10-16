# AGENTS.md

This repo is **agent-friendly**. The following tasks and prompts are designed for Codex/AI agents to review and improve the dotfiles safely.

## Safety policy (must follow)

* **Default to read-only**: list planned actions first; require explicit `approve:` marker in the issue/PR comment before executing writes.
* **Never touch real `$HOME`**. Always set:

  * `DOTFILES_TARGET=$(mktemp -d)`
  * `DOTFILES_PROFILE=personal` (or as specified)
* Prefer dry-run flags (`--dry-run`, `--target`, `stow -n`).
* Log commands before running; capture exit codes and stdout/stderr.

---

## Global context to load

* README.md (this file summarizes scope)
* CONTRIBUTING.md (tests & checks)
* bin/bootstrap
* packages/**/*
* profiles/**/*
* hosts/**/*
* test/**/*

---

## Agent task catalog

### 1) Lint & Style Audit

**Goal:** surface shell/style issues; propose autofixes.

**Prompt:**

> Analyze shell scripts under `bin/` and `packages/**`. Run `shellcheck` and `shfmt -d`. Summarize violations by file with 1-line fixes. Generate a patch that is idempotent and cross-platform. Do not execute writes; output a proposed diff.

**Success criteria:**

* Zero false positives where platform gating is required.
* Patch applies cleanly and passes checks.

---

### 2) Bootstrap Dry-Run Auditor

**Goal:** ensure `bin/bootstrap` is idempotent, supports `--dry-run`, and respects `$DOTFILES_TARGET`.

**Prompt:**

> Run `DOTFILES_TARGET=$(mktemp -d) bin/bootstrap --dry-run --target "$DOTFILES_TARGET"` on Ubuntu, Fedora, and macOS contexts. Report: (a) commands that would write to real `$HOME`, (b) package managers invoked, (c) missing preflight checks, (d) steps lacking error handling. Propose minimal diffs to fix.

**Success criteria:**

* No writes to real `$HOME`.
* Clear preflight for package managers and fonts.

---

### 3) Stow Plan Consistency Check

**Goal:** detect link collisions and overlay precedence problems.

**Prompt:**

> Compute `stow -n -v -d packages -t "$DOTFILES_TARGET" $(ls packages)` then layer `profiles/$DOTFILES_PROFILE` and `hosts/$(hostname)` overlays. Flag collisions, cycles, or files outside `$HOME`. Suggest renames or `.stow-local-ignore` rules.

**Success criteria:**

* Zero collisions after proposed changes.
* Explicit ignore files where needed.

---

### 4) Cross-Distro Install Matrix

**Goal:** verify install steps per distro and list missing packages.

**Prompt:**

> For Debian/Ubuntu and Fedora/RedHat, derive required package lists for zsh, git, curl, fonts, nvim, tmux, nvm/pyenv/rbenv. Produce scripted installers guarded by distro detection. Include uninstall/cleanup functions. Keep everything idempotent.

**Success criteria:**

* Minimal, correct package sets per distro.
* Graceful skips when tools exist.

---

### 5) Font Installer Validation

**Goal:** ensure Nerd Fonts install to correct per-user paths.

**Prompt:**

> Validate font install locations for macOS (`~/Library/Fonts`) and Linux (`~/.local/share/fonts`). Propose a script that: (1) checks presence; (2) caches downloads; (3) triggers font cache refresh on Linux; (4) is safe on repeated runs.

**Success criteria:**

* No system-wide writes; user-scoped only.
* Cached, repeatable installs.

---

### 6) Editor & Tmux Sanity

**Goal:** verify Neovim (LazyVim) and TPM bootstrap flows.

**Prompt:**

> Headless-launch Neovim to sync plugins; verify exit codes. Validate `.tmux.conf` loads TPM and can install plugins non-interactively. Provide CI-safe commands and guards when binaries are absent.

**Success criteria:**

* Non-interactive success paths documented.
* Skips cleanly on missing binaries.

---

### 7) Security Posture Review

**Goal:** surface risky defaults.

**Prompt:**

> Review SSH/GPG configs and shell rc files. Flag permissive ciphers, weak KEX, dangerous aliases (e.g., `rm -rf` shorthand), or insecure `PATH` mutations. Provide safer defaults and rationale.

**Success criteria:**

* Concrete, minimal security improvements with no UX breakage.

---

### 8) Feature Suggestions (Roadmap)

**Goal:** propose useful, low-risk enhancements.

Seed ideas:

* `bin/doctor` to print environment diagnostics.
* `DOTFILES_FEATURES="nvim,tmux,fonts"` to opt-in/out modules.
* Per-package `install-*.sh` with `--dry-run`.
* `stow --adopt` migration helper.
* Docker harness (`make docker-dry` / `make docker-install`) with distro matrix (Ubuntu, Fedora).
* Optional **chezmoi** importer/exporter for users migrating in.

**Prompt:**

> Propose ≤10 features prioritized by impact/complexity with short specs and example CLI.

---

## Example execution plan (agents)

**Read-only reconnaissance**

1. Parse README.md and `bin/bootstrap` for flags & profile handling.
2. List all files under `packages/`, `profiles/`, `hosts/`.
3. Compute link plan with `stow -n -v -d packages -t "$DOTFILES_TARGET" $(ls packages)`.

**Propose changes**
4. Emit a markdown report (sections mirror task catalog).
5. Attach unified diffs as fenced `diff` blocks.
6. Wait for maintainer `approve: <task-id>` before applying.

**Apply (after approval)**
7. Apply diffs in a temp worktree; run checks; open PR with summary and matrix results.

---

## Test harness (suggested)

Place these in `test/` (agents can call them):

* `test/smoke.sh`

  * `./test/smoke.sh dry` → wraps `bin/bootstrap --dry-run --target "$DOTFILES_TARGET"` and a full `stow -n` plan.
  * `./test/smoke.sh real` → runs the installer end-to-end against a temp `$HOME`.
  * Use `make docker-dry` / `make docker-install` to run these flows inside Ubuntu and Fedora containers (working dir `/workspace`, profile via `DOTFILES_PROFILE`).
* `test/nvim.sh` (optional)

  * Headless plugin sync and health checks (skip if `nvim` missing).

---

## Output format (for all agents)

* Start with a **1-page summary** (problems, impact, OS scope).
* Then **actionable diffs** and a **checklist** to verify.
* End with **risk notes** and **rollback steps**.

---

## Known non-goals

* Managing system-wide packages or services.
* Touching secrets or private keys.
* Enforcing a single package manager across all distros.
