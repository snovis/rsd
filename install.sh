#!/usr/bin/env bash
# rsd installer
#
# One-shot install. Registers rsd as a marketplace plugin in ~/.claude/settings.json
# AND installs the statusline to ~/.claude/hooks/. After this runs, restart Claude
# Code and rsd auto-loads everywhere — no --plugin-dir, no aliases.
#
# For dev mode (working on rsd itself), override with:
#   claude --plugin-dir ~/dev/rsd
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

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required for safe settings.json editing."
  echo "  macOS: brew install jq"
  echo "  Debian/Ubuntu: sudo apt-get install jq"
  exit 1
fi

# ── Ensure settings.json exists ─────────────────────────────────
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

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

# ── Patch settings.json: statusLine ─────────────────────────────
STATUSLINE_CMD="node \"\$HOME/.claude/hooks/rsd-statusline.js\""
TMP="$(mktemp)"
jq --arg cmd "$STATUSLINE_CMD" '
  if (.statusLine != null and (.statusLine.command // "") != $cmd) then
    .statusLine_backup = .statusLine
  else . end
  | .statusLine = { type: "command", command: $cmd }
' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
echo "  patched $SETTINGS (statusLine)"

# ── Patch settings.json: register rsd marketplace + enable plugin ───
# This is what makes rsd auto-load in every session without --plugin-dir.
TMP="$(mktemp)"
jq '
  .extraKnownMarketplaces = (.extraKnownMarketplaces // {}) |
  .extraKnownMarketplaces.snovis = {
    "source": { "source": "github", "repo": "snovis/rsd" }
  } |
  .enabledPlugins = (.enabledPlugins // {}) |
  .enabledPlugins["rsd@snovis"] = true
' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
echo "  patched $SETTINGS (extraKnownMarketplaces.snovis, enabledPlugins['rsd@snovis'])"

echo ""
echo "Done. Restart Claude Code to activate."
echo ""
echo "On first launch, Claude Code will clone snovis/rsd into its plugin cache"
echo "and auto-load /rsd:handoff, /rsd:ho, /rsd:pickup, /rsd:pu."
echo ""
echo "To check:"
echo "  /plugin marketplace list       (should show 'snovis')"
echo "  /plugin list                   (should show 'rsd@snovis' enabled)"
echo "  /rsd:handoff                   (try it in any git project)"
echo ""
echo "For dev mode on this repo, override with:"
echo "  claude --plugin-dir \"$SCRIPT_DIR\""
