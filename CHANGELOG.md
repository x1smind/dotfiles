# Changelog

All notable changes to this project will be documented in this file.

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

