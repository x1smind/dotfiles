#!/usr/bin/env bash
set -euo pipefail
# Example macOS tweaks
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2
echo "Applied basic macOS defaults. You may need to log out/in."
