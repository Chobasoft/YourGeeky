#!/usr/bin/env bash
# Smoke tests for YourGeeky. Uses a fake claude so nothing real is run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export YOURGEEKY_ALLOW_ANY_OS=1

# Fake claude and agy: record which one ran and its arguments.
for tool in claude agy; do
  cat > "$TMP/$tool" <<FAKE
#!/usr/bin/env bash
{ echo "TOOL=$tool"; for a in "\$@"; do printf '%s\n--ARG--\n' "\$a"; done; } > "\$CLAUDE_ARGS_FILE"
FAKE
  chmod +x "$TMP/$tool"
done
export YOURGEEKY_CLAUDE="$TMP/claude" YOURGEEKY_AGY="$TMP/agy" CLAUDE_ARGS_FILE="$TMP/args"
export YOURGEEKY_ENGINE_FILE="$TMP/engine" YOURGEEKY_NOTES="$TMP/My notes.txt"

fails=0
check() {
  if eval "$2"; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); fi
}

check "--version prints version" '"$ROOT/bin/yourgeeky" --version | grep -q "yourgeeky 0.3.0"'
check "--help explains usage" '"$ROOT/bin/yourgeeky" --help | grep -q "install Python"'
check "unknown option fails" '! "$ROOT/bin/yourgeeky" --bogus >/dev/null 2>&1'

# Default engine: Google's Antigravity CLI, guide and request in the opening message.
"$ROOT/bin/yourgeeky" install Python >/dev/null
check "google is the default" 'grep -q "^TOOL=agy$" "$TMP/args"'
check "agy starts interactive" 'grep -q "^-i$" "$TMP/args"'
check "agy is pointed at the guide file" 'grep -q "session-guide.md" "$TMP/args"'
check "agy can read the guide folder" 'grep -q "^--add-dir$" "$TMP/args"'
check "guide is not in the opening message" '! grep -q "Safety rules" "$TMP/args"'
check "guide file has the guide" 'grep -q "You are YourGeeky" "$ROOT/session-guide.md"'
check "guide says to explain before every command" 'grep -q "Always talk before you act" "$ROOT/session-guide.md"'
check "agy gets the request" 'grep -q "first request: install Python" "$TMP/args"'
"$ROOT/bin/yourgeeky" >/dev/null
check "agy greets with no request" 'grep -q "greet the person" "$TMP/args"'
"$ROOT/bin/yourgeeky" > "$TMP/start-out"
check "says it is using Google" 'grep -q "using Google" "$TMP/start-out"'
check "tells people how to say yes" 'grep -q "type y and press Return" "$TMP/start-out"'
check "guide says what to press" 'grep -q "Press Return to" "$ROOT/session-guide.md"'
check "says when it is safe to close the window" 'grep -q "You can close this window" "$TMP/start-out"'
check "guide explains how to leave" 'grep -q "/exit (with the slash) and press Return" "$ROOT/session-guide.md"'
check "bad --use value fails" '! "$ROOT/bin/yourgeeky" --use bogus >/dev/null 2>&1'

# Switching to Claude Code.
"$ROOT/bin/yourgeeky" --use claude >/dev/null
check "--use claude is remembered" 'grep -q "^claude$" "$TMP/engine"'
"$ROOT/bin/yourgeeky" install Python >/dev/null
check "claude runs after switching" 'grep -q "^TOOL=claude$" "$TMP/args"'
check "request is passed to claude" 'grep -q "^install Python$" "$TMP/args"'
check "guide is appended" 'grep -q "You are YourGeeky" "$TMP/args"'
check "commands hidden by default" 'grep -q "Hide raw commands" "$TMP/args"'
check "placeholder replaced" '! grep -q "COMMANDS_MODE" "$TMP/args"'

"$ROOT/bin/yourgeeky" --show-commands > "$TMP/start-out"
check "says it is using Claude" 'grep -q "using Claude Code" "$TMP/start-out"'
check "--show-commands shows commands" 'grep -q "Show each command" "$TMP/args"'

# Notes of what was done.
check "guide points at the notes file" 'grep -q "My notes.txt" "$TMP/args"'
check "notes placeholder replaced" '! grep -q "\"NOTES_FILE\"" "$TMP/args"'
check "--notes with no notes explains" '"$ROOT/bin/yourgeeky" --notes | grep -q "no notes yet"'
printf '2 Nov 2026\n- Installed Python.\n' > "$TMP/My notes.txt"
check "--notes shows the notes" '"$ROOT/bin/yourgeeky" --notes | grep -q "Installed Python"'

# Installer, from this checkout into a temp home.
HOME="$TMP/home" PATH="/usr/bin:/bin" YOURGEEKY_SKIP_ENGINE=1 YOURGEEKY_DIR="$TMP/home/.yourgeeky" \
  YOURGEEKY_BIN_DIR="$TMP/home/.local/bin" bash "$ROOT/docs/install.sh" >/dev/null
check "installer links the command" '[ -L "$TMP/home/.local/bin/yourgeeky" ]'
check "installer adds PATH to .zshrc" 'grep -q ".local/bin" "$TMP/home/.zshrc"'
check "installer defaults to google" 'grep -q "^google$" "$TMP/home/.yourgeeky/engine"'
printf 'claude\n' > "$TMP/home/.yourgeeky/engine"
HOME="$TMP/home" PATH="/usr/bin:/bin" YOURGEEKY_SKIP_ENGINE=1 YOURGEEKY_SKIP_APP=1 YOURGEEKY_DIR="$TMP/home/.yourgeeky" \
  YOURGEEKY_BIN_DIR="$TMP/home/.local/bin" bash "$ROOT/docs/install.sh" > "$TMP/reinstall-out"
check "reinstall keeps the chosen AI" 'grep -q "^claude$" "$TMP/home/.yourgeeky/engine"'
check "reinstall says which AI it kept" 'grep -q "keep using Claude Code" "$TMP/reinstall-out"'
printf 'google\n' > "$TMP/home/.yourgeeky/engine"
check "installed command runs via symlink" '"$TMP/home/.local/bin/yourgeeky" --version | grep -q 0.3.0'
YOURGEEKY_ENGINE_FILE="$TMP/home/.yourgeeky/engine" "$TMP/home/.local/bin/yourgeeky" hi >/dev/null
check "installed command finds guide" 'grep -q "You are YourGeeky" "$TMP/args"'
check "installer copies the icon picture" '[ -f "$TMP/home/.yourgeeky/assets/icon.png" ]'
check "no app made off a Mac unless asked" '[ ! -e "$TMP/home/Applications/YourGeeky.app" ]'

# The Dock app, built into a chosen folder (the Dock itself is only touched on a Mac).
HOME="$TMP/home" PATH="/usr/bin:/bin" YOURGEEKY_SKIP_ENGINE=1 YOURGEEKY_DIR="$TMP/home/.yourgeeky" \
  YOURGEEKY_BIN_DIR="$TMP/home/.local/bin" YOURGEEKY_APP_DIR="$TMP/apps" YOURGEEKY_SKIP_DOCK=1 \
  bash "$ROOT/docs/install.sh" > "$TMP/install-out"
APP="$TMP/apps/YourGeeky.app"
check "installer makes the app" '[ -d "$APP/Contents" ]'
check "app launcher can run" '[ -x "$APP/Contents/MacOS/YourGeeky" ]'
check "app opens Terminal" 'grep -q "open -a Terminal" "$APP/Contents/MacOS/YourGeeky"'
check "app names its launcher" 'grep -q "<string>YourGeeky</string>" "$APP/Contents/Info.plist"'
check "app settings are valid" 'python3 -c "import plistlib,sys; d=plistlib.load(open(sys.argv[1],\"rb\")); assert d[\"CFBundleExecutable\"]==\"YourGeeky\"" "$APP/Contents/Info.plist"'
check "start file can run" '[ -x "$APP/Contents/Resources/start.command" ]'
check "start file runs yourgeeky" 'grep -q "$TMP/home/.yourgeeky/bin/yourgeeky" "$APP/Contents/Resources/start.command"'
check "start file finds the AI tools" 'grep -q "\$HOME/.local/bin" "$APP/Contents/Resources/start.command"'
check "start file has valid syntax" 'bash -n "$APP/Contents/Resources/start.command"'
check "installer tells you about the app" 'grep -q "Added YourGeeky" "$TMP/install-out"'

if [ "$fails" -gt 0 ]; then echo "$fails test(s) failed"; exit 1; fi
echo "All tests passed"
