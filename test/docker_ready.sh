#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/docker-ready.XXXXXX")"
trap 'rm -rf "${TMP_DIR}"' EXIT

stub_log="${TMP_DIR}/docker.log"
cat <<'EOF' > "${TMP_DIR}/docker"
#!/usr/bin/env bash
set -euo pipefail
log_file="__LOG_FILE__"
printf '%s\n' "$*" >> "$log_file"
case "${1:-}" in
  context)
    exit 0
    ;;
  info)
    echo "stub: docker info unavailable" >&2
    exit 125
    ;;
esac
echo "stub docker invoked unexpectedly: $*" >&2
exit 99
EOF
python3 - <<PY
import pathlib
stub_path = pathlib.Path("${TMP_DIR}/docker")
stub_path.write_text(stub_path.read_text().replace("__LOG_FILE__", "${stub_log}"))
stub_path.chmod(0o755)
PY

PATH="${TMP_DIR}:${PATH}"
export PATH

set +e
output="$({ make -C "${REPO_DIR}" docker-ready; } 2>&1)"
status=$?
set -e

printf '%s\n' "$output"

if [[ $status -eq 0 ]]; then
  echo "docker-ready succeeded unexpectedly under simulated failure." >&2
  exit 1
fi

if ! grep -q "❌ Docker not running or socket not accessible" <<<"$output"; then
  echo "Expected friendly failure message was not emitted." >&2
  exit 1
fi

expected_calls=$(cat "${stub_log}")
if [[ "$expected_calls" != $'context use default\ninfo' ]]; then
  echo "docker-ready invoked unexpected docker commands: ${expected_calls}" >&2
  exit 1
fi

echo "✅ docker-ready correctly detected missing daemon"
