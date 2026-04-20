#!/usr/bin/env bash
# rsd installer
#
# Installs the statusline into ~/.claude/hooks/ and patches settings.json
# to register it. For the plugin itself (commands + hooks), use:
#
#   claude --plugin-dir "$(cd "$(dirname "$0")" && pwd)"
#
# Or add a shell alias for persistent loading (see README).
#
# Safe to re-run.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "rsd installer"
echo "  CLAUDE_DIR: $CLAUDE_DIR"
echo "  source:    $SCRIPT_DIR"
echo ""

# ── Install statusline (symlink so git pull updates are live) ───
mkdir -p "$HOOKS_DIR"
STATUSLINE_DEST="$HOOKS_DIR/rsd-statusline.js"
if [ -e "$STATUSLINE_DEST" ] && [ ! -L "$STATUSLINE_DEST" ]; then
  echo "  backing up existing $STATUSLINE_DEST to ${STATUSLINE_DEST}.backup"
  mv "$STATUSLINE_DEST" "${STATUSLINE_DEST}.backup"
fi
if [ -L "$STATUSLINE_DEST" ]; then rm "$STATUSLINE_DEST"; fi
ln -s "$SCRIPT_DIR/hooks/statusline.js" "$STATUSLINE_DEST"
chmod +x "$SCRIPT_DIR/hooks/statusline.js" "$SCRIPT_DIR/hooks/context-monitor.js"
echo "  linked statusline: $STATUSLINE_DEST -> $SCRIPT_DIR/hooks/statusline.js"

# ── Patch settings.json for statusline ──────────────────────────
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

NEW_CMD="node \"\$HOME/.claude/hooks/rsd-statusline.js\""

if command -v jq >/dev/null 2>&1; then
  TMP="$(mktemp)"
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
echo "Statusline installed. Restart Claude Code to activate."
echo ""
echo "── To load the rsd plugin (commands + hooks) ─────────────────"
echo ""
echo "  Testing (per-session):"
echo "    claude --plugin-dir \"$SCRIPT_DIR\""
echo ""
echo "  Persistent (add to ~/.zshrc or ~/.bashrc):"
echo "    alias claude='claude --plugin-dir \"$SCRIPT_DIR\"'"
echo ""
echo "Then try: /rsd:handoff in any git project."
