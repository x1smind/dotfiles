#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

MODE="${1:-stub}"

usage() {
  echo "Usage: $0 [stub|real]" >&2
}

create_common_stubs() {
  cat <<'EOF' > "${STUB_ROOT}/xcode-select"
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  -p)
    echo "/Library/Developer/CommandLineTools"
    exit 0
    ;;
  --install)
    echo "stub: xcode-select --install" >&2
    exit 0
    ;;
esac
exit 0
EOF
  chmod +x "${STUB_ROOT}/xcode-select"

  cat <<'EOF' > "${STUB_ROOT}/curl"
#!/usr/bin/env bash
echo "curl stub invoked unexpectedly: $*" >&2
exit 99
EOF
  chmod +x "${STUB_ROOT}/curl"
}

create_brew_stub() {
  local dest="$1"
  local prefix="$2"
  local log_file="$3"
  local state_file="$4"
  python3 - "$dest" "$prefix" "$log_file" "$state_file" <<'PY'
import pathlib
import sys
import textwrap

dest = pathlib.Path(sys.argv[1])
prefix, log_file, state_file = sys.argv[2:]
template = textwrap.dedent("""\
#!/usr/bin/env bash
set -euo pipefail

BREW_PREFIX="__BREW_PREFIX__"
LOG_FILE="__LOG_FILE__"
STATE_FILE="__STATE_FILE__"

init_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    touch "$STATE_FILE"
  fi
}

write_log() {
  printf '%s\n' "$*" >> "$LOG_FILE"
}

current_taps() {
  init_state
  while IFS= read -r tap; do
    [[ -n "$tap" ]] && printf '%s\n' "$tap"
  done < "$STATE_FILE"
}

remove_tap() {
  local target="$1"
  init_state
  local tmp="${STATE_FILE}.tmp"
  : > "$tmp"
  while IFS= read -r tap; do
    [[ -n "$tap" && "$tap" != "$target" ]] && printf '%s\n' "$tap" >> "$tmp"
  done < "$STATE_FILE"
  mv "$tmp" "$STATE_FILE"
}

cmd="${1:-}"
case "$cmd" in
  --prefix)
    printf '%s\n' "$BREW_PREFIX"
    ;;
  shellenv)
    printf 'export HOMEBREW_PREFIX=%s\n' "$BREW_PREFIX"
    printf 'export PATH=%s/bin:$PATH\n' "$BREW_PREFIX"
    ;;
  update)
    shift
    write_log "update $*"
    ;;
  tap)
    shift || true
    current_taps
    ;;
  untap)
    shift
    target="${1:-}"
    write_log "untap $target"
    remove_tap "$target"
    ;;
  bundle)
    shift
    write_log "bundle $*"
    ;;
  *)
    write_log "$cmd $*"
    ;;
esac
exit 0
""")
for placeholder, value in (
    ("__BREW_PREFIX__", prefix),
    ("__LOG_FILE__", log_file),
    ("__STATE_FILE__", state_file),
):
    template = template.replace(placeholder, value)
dest.write_text(template)
PY
  chmod +x "$dest"
}

assert_shellenv_line() {
  local expected_path="$1"
  local file="$2"
  [[ -f "$file" ]] || { echo "Expected $file to exist" >&2; return 1; }
  local count
  count="$(grep -c 'brew shellenv' "$file" || true)"
  if [[ "$count" -ne 1 ]]; then
    echo "Expected a single Homebrew shellenv line in $file (found $count)" >&2
    return 1
  fi
  local line
  line="$(grep 'brew shellenv' "$file")"
  if [[ "$line" != *"$expected_path"* ]]; then
    echo "Expected shellenv line to reference $expected_path; got: $line" >&2
    return 1
  fi
}

with_case() {
  local label="$1"
  local fn="$2"
  echo ">> macOS stub test: $label"
  (
    set -euo pipefail
    CASE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.case.XXXXXX")"
    trap 'rm -rf "$CASE_DIR"' EXIT
    HOME_DIR="${CASE_DIR}/home"
    mkdir -p "$HOME_DIR"
    STUB_ROOT="${CASE_DIR}/stubs"
    mkdir -p "$STUB_ROOT"

    export HOME="$HOME_DIR"
    export DOTFILES_TARGET="$HOME_DIR"
    export DOTFILES_TEST_MODE="macos"
    export DOTFILES_FAKE_UNAME="Darwin"
    PATH="${STUB_ROOT}:/usr/bin:/bin"
    export PATH

    create_common_stubs

    set --
    # shellcheck source=bin/bootstrap
    source "${REPO_DIR}/bin/bootstrap"

    "$fn"
  )
}

case_present_arm64() {
  export DOTFILES_FAKE_ARCH="arm64"
  local brew_prefix="${CASE_DIR}/opt-homebrew"
  local brew_bin_dir="${brew_prefix}/bin"
  local brew_log="${CASE_DIR}/brew-arm64.log"
  local brew_state="${CASE_DIR}/brew-arm64.tap"
  mkdir -p "$brew_bin_dir"
  touch "$brew_log"
  printf 'homebrew/cask-fonts\n' > "$brew_state"
  create_brew_stub "${brew_bin_dir}/brew" "$brew_prefix" "$brew_log" "$brew_state"
  PATH="${brew_bin_dir}:${PATH}"
  export PATH

  install_prereqs_macos

  local brew_cmd
  brew_cmd="$(command -v brew)"
  [[ -n "$brew_cmd" ]] || { echo "brew not detected in arm64 present case" >&2; exit 1; }
  assert_shellenv_line "$brew_cmd" "${HOME_DIR}/.zprofile"
  [[ ":$PATH:" == *":${brew_prefix}/bin:"* ]] || { echo "PATH missing ${brew_prefix}/bin" >&2; exit 1; }
  grep -q "bundle --file ${REPO_DIR}/macos/Brewfile" "$brew_log" || { echo "brew bundle not invoked (arm64)" >&2; exit 1; }
  grep -q '^untap homebrew/cask-fonts$' "$brew_log" || { echo "preflight did not untap deprecated tap (arm64)" >&2; exit 1; }

  local snapshot="${CASE_DIR}/zprofile.snapshot"
  cp "${HOME_DIR}/.zprofile" "$snapshot"
  install_prereqs_macos
  cmp -s "$snapshot" "${HOME_DIR}/.zprofile" || { echo ".zprofile changed on rerun (arm64)" >&2; exit 1; }
  local untap_count
  untap_count="$(grep -c '^untap homebrew/cask-fonts$' "$brew_log" || true)"
  [[ "$untap_count" -eq 1 ]] || { echo "untap should run once (arm64); saw ${untap_count}" >&2; exit 1; }
  ! grep -qx 'homebrew/cask-fonts' "$brew_state" || { echo "deprecated tap persisted after untap (arm64)" >&2; exit 1; }
}

case_present_intel() {
  export DOTFILES_FAKE_ARCH="x86_64"
  local brew_prefix="${CASE_DIR}/usr-local-homebrew"
  local brew_bin_dir="${brew_prefix}/bin"
  local brew_log="${CASE_DIR}/brew-intel.log"
  local brew_state="${CASE_DIR}/brew-intel.tap"
  mkdir -p "$brew_bin_dir"
  touch "$brew_log"
  printf 'homebrew/cask-fonts\nhomebrew/core\n' > "$brew_state"
  create_brew_stub "${brew_bin_dir}/brew" "$brew_prefix" "$brew_log" "$brew_state"
  PATH="${brew_bin_dir}:${PATH}"
  export PATH

  install_prereqs_macos

  local brew_cmd
  brew_cmd="$(command -v brew)"
  [[ -n "$brew_cmd" ]] || { echo "brew not detected in intel present case" >&2; exit 1; }
  assert_shellenv_line "$brew_cmd" "${HOME_DIR}/.zprofile"
  [[ ":$PATH:" == *":${brew_prefix}/bin:"* ]] || { echo "PATH missing ${brew_prefix}/bin" >&2; exit 1; }
  grep -q "bundle --file ${REPO_DIR}/macos/Brewfile" "$brew_log" || { echo "brew bundle not invoked (intel)" >&2; exit 1; }
  grep -q '^untap homebrew/cask-fonts$' "$brew_log" || { echo "preflight did not untap deprecated tap (intel)" >&2; exit 1; }

  local snapshot="${CASE_DIR}/zprofile-intel.snapshot"
  cp "${HOME_DIR}/.zprofile" "$snapshot"
  install_prereqs_macos
  cmp -s "$snapshot" "${HOME_DIR}/.zprofile" || { echo ".zprofile changed on rerun (intel)" >&2; exit 1; }
  local untap_count
  untap_count="$(grep -c '^untap homebrew/cask-fonts$' "$brew_log" || true)"
  [[ "$untap_count" -eq 1 ]] || { echo "untap should run once (intel); saw ${untap_count}" >&2; exit 1; }
  ! grep -qx 'homebrew/cask-fonts' "$brew_state" || { echo "deprecated tap persisted after untap (intel)" >&2; exit 1; }
}

case_install_fresh() {
  export DOTFILES_FAKE_ARCH="arm64"
  local brew_prefix="${CASE_DIR}/opt-homebrew-install"
  local brew_bin_dir="${brew_prefix}/bin"
  local brew_log="${CASE_DIR}/brew-install.log"
  local brew_state="${CASE_DIR}/brew-install.tap"
  local brew_template="${CASE_DIR}/brew-template.sh"
  touch "$brew_log"
  printf 'homebrew/cask-fonts\n' > "$brew_state"
  mkdir -p "$brew_prefix"
  mkdir -p "$(dirname "$brew_template")"
  create_brew_stub "$brew_template" "$brew_prefix" "$brew_log" "$brew_state"

  local installer="${STUB_ROOT}/install-brew"
  python3 - "$installer" "$brew_bin_dir" "$brew_template" <<'PY'
import pathlib
import sys
import textwrap

dest = pathlib.Path(sys.argv[1])
bin_dir, template = sys.argv[2:]
script = textwrap.dedent(f"""\
#!/usr/bin/env bash
set -euo pipefail

bin_dir="{bin_dir}"
template="{template}"

mkdir -p "$bin_dir"
cp "$template" "$bin_dir/brew"
chmod +x "$bin_dir/brew"
""")
dest.write_text(script)
PY
  chmod +x "$installer"

  export DOTFILES_BREW_INSTALLER="$installer"
  PATH="${brew_bin_dir}:${PATH}"
  export PATH

  install_prereqs_macos

  local brew_cmd
  brew_cmd="$(command -v brew)"
  [[ -x "$brew_cmd" ]] || { echo "brew installer stub did not create brew" >&2; exit 1; }
  assert_shellenv_line "$brew_cmd" "${HOME_DIR}/.zprofile"
  [[ ":$PATH:" == *":${brew_prefix}/bin:"* ]] || { echo "PATH missing ${brew_prefix}/bin after install" >&2; exit 1; }
  grep -q "bundle --file ${REPO_DIR}/macos/Brewfile" "$brew_log" || { echo "brew bundle not invoked after install" >&2; exit 1; }
  grep -q '^untap homebrew/cask-fonts$' "$brew_log" || { echo "preflight did not untap deprecated tap after install" >&2; exit 1; }

  local snapshot="${CASE_DIR}/zprofile-install.snapshot"
  cp "${HOME_DIR}/.zprofile" "$snapshot"
  install_prereqs_macos
  cmp -s "$snapshot" "${HOME_DIR}/.zprofile" || { echo ".zprofile changed on rerun after install" >&2; exit 1; }
  local untap_count
  untap_count="$(grep -c '^untap homebrew/cask-fonts$' "$brew_log" || true)"
  [[ "$untap_count" -eq 1 ]] || { echo "untap should run once after install; saw ${untap_count}" >&2; exit 1; }
  ! grep -qx 'homebrew/cask-fonts' "$brew_state" || { echo "deprecated tap persisted after untap (install)" >&2; exit 1; }
}

run_stub_tests() {
  with_case "Homebrew present (arm64)" case_present_arm64
  with_case "Homebrew present (Intel)" case_present_intel
  with_case "Homebrew installed when missing" case_install_fresh
  echo "✅ macOS stub tests passed"
}

run_real_test() {
  tmp_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.bootstrap.XXXXXX")"
  trap 'rm -rf "$tmp_home"' EXIT
  DOTFILES_TARGET="$tmp_home"
  DOTFILES_PROFILE="${DOTFILES_PROFILE:-personal}"
  export DOTFILES_TARGET DOTFILES_PROFILE
  "${REPO_DIR}/bin/bootstrap" --dry-run --target "$DOTFILES_TARGET" --profile "$DOTFILES_PROFILE"
}

case "$MODE" in
  stub)
    run_stub_tests
    ;;
  real)
    run_real_test
    ;;
  *)
    usage
    exit 2
    ;;
esac
