#!/usr/bin/env bash
# rsd installer — installs the plugin, registers the statusline, backs up
# any existing config. Safe to re-run.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "rsd installer"
echo "  CLAUDE_DIR: $CLAUDE_DIR"
echo "  source:    $SCRIPT_DIR"
echo ""

# ── Install plugin ──────────────────────────────────────────────
mkdir -p "$PLUGINS_DIR"
PLUGIN_DEST="$PLUGINS_DIR/rsd"
if [ -e "$PLUGIN_DEST" ] && [ ! -L "$PLUGIN_DEST" ]; then
  echo "  backing up existing $PLUGIN_DEST to ${PLUGIN_DEST}.backup"
  mv "$PLUGIN_DEST" "${PLUGIN_DEST}.backup"
fi
if [ -L "$PLUGIN_DEST" ]; then rm "$PLUGIN_DEST"; fi
ln -s "$SCRIPT_DIR" "$PLUGIN_DEST"
echo "  linked plugin: $PLUGIN_DEST -> $SCRIPT_DIR"

# ── Install statusline (symlink so git pull updates are live) ───
mkdir -p "$HOOKS_DIR"
STATUSLINE_DEST="$HOOKS_DIR/rsd-statusline.js"
if [ -e "$STATUSLINE_DEST" ] && [ ! -L "$STATUSLINE_DEST" ]; then
  echo "  backing up existing $STATUSLINE_DEST to ${STATUSLINE_DEST}.backup"
  mv "$STATUSLINE_DEST" "${STATUSLINE_DEST}.backup"
fi
if [ -L "$STATUSLINE_DEST" ]; then rm "$STATUSLINE_DEST"; fi
ln -s "$SCRIPT_DIR/hooks/statusline.js" "$STATUSLINE_DEST"
chmod +x "$SCRIPT_DIR/hooks/statusline.js"
echo "  linked statusline: $STATUSLINE_DEST -> $SCRIPT_DIR/hooks/statusline.js"

# ── Patch settings.json for statusline ──────────────────────────
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# Back up existing statusLine entry if it's different from what we'd set.
NEW_CMD="node \"\$HOME/.claude/hooks/rsd-statusline.js\""

if command -v jq >/dev/null 2>&1; then
  TMP="$(mktemp)"
  # If an existing statusLine exists and isn't ours, preserve it under statusLine_backup.
  jq --arg cmd "$NEW_CMD" '
    if (.statusLine != null and (.statusLine.command // "") != $cmd) then
      .statusLine_backup = .statusLine
    else . end
    | .statusLine = { type: "command", command: $cmd }
  ' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
  echo "  patched $SETTINGS (statusLine)"
else
  echo ""
  echo "  ⚠ jq not found — add this manually to $SETTINGS:"
  echo ""
  echo "    \"statusLine\": { \"type\": \"command\", \"command\": \"$NEW_CMD\" }"
  echo ""
fi

echo ""
echo "Done. Restart Claude Code to activate rsd."
echo "Try: /rsd:handoff in any project with a git repo."
