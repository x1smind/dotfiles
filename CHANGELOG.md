# Changelog

All notable changes to this project will be documented in this file.

## [v0.5.0] - 2025-10-24

### Added
- Bootstrap wizard for interactive profile and feature selection, with a `--no-prompt` escape hatch for CI and scripts.
- `bin/profile-git` helper shared across work/personal overlays, plus documentation on customising profile emails, names, and signing defaults.
- Telescope file browser plugin and `<leader>fb` shortcut for quick navigation alongside the existing live-grep/file-finder maps.

### Changed
- Docker smoke workflow now caches BuildKit layers per distro, reusing images across runs while the local `make` harness skips redundant rebuilds.
- `nvm` provisioning enables Corepack after setting the default LTS release so `pnpm`/`yarn` are available immediately.

### Fixed
- Linux fallback package lists in the bootstrapper were brought back in sync with the repository manifests.
- Smoke harness logging trimmed and streamlined for clearer output during CI runs.

## [v0.4.0] - 2025-10-20

### Added
- Neovim 0.11.4 distribution with Lazy.nvim-based config, including neo-tree v3, Telescope defaults, and requested colorschemes.
- README rollback guide describing how to undo bootstrap operations.

### Changed
- Linux bootstraps fetch architecture-specific Neovim tarballs and ship fallback apt/dnf package lists so remote installs succeed even before cloning.
- Zsh aliases, tmux defaults, and dev-shell environment exports updated to match daily workflows.
- `.gitignore` cleaned up to stop ignoring `.home/` and other new artifacts.

### Fixed
- macOS flow now prompts for Xcode Command Line Tools when git is missing and surfaces actionable guidance when Homebrew locks are not writable.
- Bootstrap reuses existing pyenv/rbenv installs and preserves any pre-existing global git identity when linking dotfiles.
- Telescope finds hidden files and uses the fzf-native backend for faster search.

## [v0.3.0] - 2025-10-17

### Added
- Linux developer container image with GitHub/Codex integration, host SSH/Docker passthrough, and supporting docs (`feat(dev): expand container workflow tooling`).
- macOS smoke-test harness and CI workflow to complement the existing Docker matrix (`feat(macos): add macOS smoke tests, CI job, and Brewfile migration`).

### Fixed
- Bootstrapper now backs up existing dotfiles before stowing and installs required build dependencies in dry-run mode (`fix(bootstrap): back up conflicts and add build deps`).
- Guarded hostname detection for Linux hosts and kept Docker smoke CI in sync (`fix(bootstrap): guard hostname and sync docker smoke ci`).

### Documentation
- Reorganized README migration notes and documented automation expectations for contributors and agents.

### Tooling
- Added Docker dry/real smoke workflows and tightened repository hygiene with a root `.gitignore`.

## [v0.2.1] - 2025-10-07

### Added
- Bootstrapping automatically installs GNU Stow and documents the administrator requirement (`bootstrap: auto-install stow and document admin requirement`).

## [v0.2.0-beta] - 2025-10-07

### Added
- Initial public beta with cross-platform dotfiles, Stow-based layout, and bootstrap harness.
