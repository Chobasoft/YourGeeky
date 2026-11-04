#!/usr/bin/env bash
# Installs YourGeeky into ~/.yourgeeky, puts the yourgeeky command on your PATH,
# and sets up the AI it uses: Google's free Antigravity CLI, or Claude Code for
# people with a paid Claude plan.
#
#   curl -fsSL https://yourgeeky.com/install.sh | bash
#
# This file lives in docs/ so the website serves it at yourgeeky.com/install.sh.
#
# Run from a downloaded copy of the repo, it installs that copy instead.

set -euo pipefail

REPO_TARBALL="${YOURGEEKY_TARBALL:-https://github.com/sbattelle-coder/YourGeeky/archive/refs/heads/main.tar.gz}"
INSTALL_DIR="${YOURGEEKY_DIR:-$HOME/.yourgeeky}"
BIN_DIR="${YOURGEEKY_BIN_DIR:-$HOME/.local/bin}"

say() { printf '%s\n' "$*"; }

say "Installing YourGeeky..."

src=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$here/../bin/yourgeeky" ]; then
    src="$(cd "$here/.." && pwd)"
  fi
fi

tmp=""
if [ -z "$src" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "$REPO_TARBALL" | tar -xz -C "$tmp" --strip-components 1
  src="$tmp"
fi

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR" "$BIN_DIR"
cp -R "$src/bin" "$src/prompts" "$src/assets" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/bin/yourgeeky"
ln -sf "$INSTALL_DIR/bin/yourgeeky" "$BIN_DIR/yourgeeky"

# Make sure new Terminal windows can find the command.
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    rc="$HOME/.zshrc"
    line="export PATH=\"$BIN_DIR:\$PATH\""
    if ! grep -qsF "$line" "$rc"; then
      printf '\n# Added by YourGeeky\n%s\n' "$line" >> "$rc"
    fi
    say "Open a new Terminal window so it can find YourGeeky."
    ;;
esac

# Make a YourGeeky app, so people can start it from the Dock or the Applications
# folder instead of opening Terminal and typing. Clicking it opens a Terminal
# window with YourGeeky already running.
make_app() {
  local parent="${YOURGEEKY_APP_DIR:-}"
  if [ -z "$parent" ]; then
    [ "$(uname -s)" = "Darwin" ] || return 0
    if [ -d /Applications ] && [ -w /Applications ]; then
      parent="/Applications"
    else
      parent="$HOME/Applications"
    fi
  fi
  local app="$parent/YourGeeky.app"
  rm -rf "$app"
  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

  cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>YourGeeky</string>
  <key>CFBundleDisplayName</key><string>YourGeeky</string>
  <key>CFBundleIdentifier</key><string>com.yourgeeky.app</string>
  <key>CFBundleExecutable</key><string>YourGeeky</string>
  <key>CFBundleIconFile</key><string>YourGeeky</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>10.13</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

  # Terminal runs a .command file when asked to open it, without needing any
  # extra permission to control Terminal.
  cat > "$app/Contents/Resources/start.command" <<START
#!/bin/bash
export PATH="$BIN_DIR:\$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH"
clear
exec "$INSTALL_DIR/bin/yourgeeky"
START
  chmod +x "$app/Contents/Resources/start.command"

  cat > "$app/Contents/MacOS/YourGeeky" <<'LAUNCH'
#!/bin/bash
open -a Terminal "$(cd "$(dirname "$0")/../Resources" && pwd)/start.command"
LAUNCH
  chmod +x "$app/Contents/MacOS/YourGeeky"

  # The Geeky picture, turned into a Mac icon with Apple's built-in tools.
  if [ -f "$INSTALL_DIR/assets/icon.png" ] && command -v sips >/dev/null 2>&1 && command -v iconutil >/dev/null 2>&1; then
    local set="$INSTALL_DIR/YourGeeky.iconset" size
    rm -rf "$set"; mkdir -p "$set"
    for size in 16 32 128 256 512; do
      sips -z "$size" "$size" "$INSTALL_DIR/assets/icon.png" --out "$set/icon_${size}x${size}.png" >/dev/null 2>&1 || true
      sips -z $((size * 2)) $((size * 2)) "$INSTALL_DIR/assets/icon.png" --out "$set/icon_${size}x${size}@2x.png" >/dev/null 2>&1 || true
    done
    iconutil -c icns "$set" -o "$app/Contents/Resources/YourGeeky.icns" >/dev/null 2>&1 || true
    rm -rf "$set"
  fi
  touch "$app"
  app_made=1

  # Put it in the Dock, once, and only say so if it really is there.
  local where="your Applications folder"
  [ "$parent" = "/Applications" ] || where="the Applications folder in your home folder"
  if [ "$(uname -s)" = "Darwin" ] && [ -z "${YOURGEEKY_SKIP_DOCK:-}" ] && command -v defaults >/dev/null 2>&1; then
    if ! defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q "YourGeeky.app"; then
      local url
      url="file://$(printf '%s' "$app" | sed 's/ /%20/g')/"
      defaults write com.apple.dock persistent-apps -array-add \
        "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$url</string><key>_CFURLStringType</key><integer>15</integer></dict></dict></dict>" \
        && killall Dock >/dev/null 2>&1 || true
    fi
    if defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q "YourGeeky.app"; then
      say "Added YourGeeky to your Dock and $where."
    else
      say "Added YourGeeky to $where."
      say "To put it in your Dock, drag the YourGeeky icon from that Finder window onto the Dock."
      open "$parent" >/dev/null 2>&1 || true
    fi
  else
    say "Added YourGeeky to $where."
  fi
}

app_made=""
if [ -z "${YOURGEEKY_SKIP_APP:-}" ]; then
  make_app || say "(Couldn't make the YourGeeky icon. You can still start it by typing yourgeeky.)"
fi

# Choose and set up the AI that YourGeeky uses. Google's is free; Claude Code
# needs a paid Claude plan.
engine="${YOURGEEKY_ENGINE:-}"
if [ -z "$engine" ]; then
  engine="google"
  if [ -r /dev/tty ] && { : < /dev/tty; } 2>/dev/null; then
    say ""
    say "YourGeeky can use Google's free AI, or Claude Code if you already pay for a Claude plan."
    printf 'Do you have a paid Claude plan (Pro or Max)? Most people answer n. [y/n] '
    answer=""
    read -r answer < /dev/tty || true
    case "$answer" in [Yy]*) engine="claude" ;; esac
  fi
fi
printf '%s\n' "$engine" > "$INSTALL_DIR/engine"

if [ -z "${YOURGEEKY_SKIP_ENGINE:-}" ]; then
  if [ "$engine" = "claude" ]; then
    if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
      say "Claude Code is already set up."
    else
      say ""
      say "Setting up Claude Code (the AI assistant from Anthropic)..."
      curl -fsSL https://claude.ai/install.sh | bash
    fi
  else
    if command -v agy >/dev/null 2>&1 || [ -x "$HOME/.local/bin/agy" ]; then
      say "Google's AI is already set up."
    else
      say ""
      say "Setting up Google's free AI (Antigravity CLI)..."
      curl -fsSL https://antigravity.google/cli/install.sh | bash
    fi
  fi
fi

say ""
if [ -n "$app_made" ]; then
  say "All set. To start, click YourGeeky in your Dock, or type:  yourgeeky"
else
  say "All set. To start, type:  yourgeeky"
fi
if [ "$engine" = "claude" ]; then
  say "The first time, you'll be asked to sign in to your Claude account."
else
  say "The first time, you'll be asked to sign in with your Google account. It's free."
fi
