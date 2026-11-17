#!/usr/bin/env bash
# PreToolUse hook for the Bash tool: guard `git push`.
#
# Reads the hook payload (JSON) on stdin. If the command is a git push, runs
# the merchant console's tests and production build. Exits 2 to block the push
# if either fails (stderr is shown to Claude and the user); exits 0 otherwise.

set -u

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
APP_DIR="$PROJECT_DIR/build-battle/merchant-console"
LOG_DIR="${TMPDIR:-/tmp}/claude-pre-push"

# Windows Git Bash often lacks Node on PATH; add the default install location.
if ! command -v node >/dev/null 2>&1 && [ -d "/c/Program Files/nodejs" ]; then
  PATH="$PATH:/c/Program Files/nodejs"
fi
if ! command -v node >/dev/null 2>&1; then
  echo "pre-push-check: node not found; cannot inspect the command, allowing it." >&2
  exit 0
fi

payload="$(cat)"
command="$(printf '%s' "$payload" | node -e '
  let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
    try { process.stdout.write(String(JSON.parse(s).tool_input?.command ?? "")) } catch { }
  })')"

# Match `git push`, allowing global options in between (git -C dir push, git -c k=v push).
if ! printf '%s' "$command" | grep -Eq '(^|[;&|(`[:space:]])git([[:space:]]+(-C|-c)[[:space:]]+[^[:space:]]+|[[:space:]]+--?[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)'; then
  exit 0
fi

if [ ! -f "$APP_DIR/package.json" ]; then
  echo "pre-push-check: $APP_DIR/package.json not found; skipping checks." >&2
  exit 0
fi

mkdir -p "$LOG_DIR"
test_log="$LOG_DIR/test.log"
build_log="$LOG_DIR/build.log"

cd "$APP_DIR" || exit 0

if ! npm test >"$test_log" 2>&1; then
  {
    echo "Push blocked: tests failed (npm test in build-battle/merchant-console)."
    echo "See the output with: cat \"$test_log\""
    echo "--- last lines ---"
    tail -n 20 "$test_log"
  } >&2
  exit 2
fi

if ! npm run build >"$build_log" 2>&1; then
  {
    echo "Push blocked: build failed (npm run build in build-battle/merchant-console)."
    echo "See the output with: cat \"$build_log\""
    echo "--- last lines ---"
    tail -n 20 "$build_log"
  } >&2
  exit 2
fi

exit 0
