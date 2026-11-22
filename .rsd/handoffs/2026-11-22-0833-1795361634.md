# Handoff

Written: 2026-07-07 18:21 · Context used: —%
Branch: main · Last commit: a5a9141

## What we're working on

Making rsd installable on Windows. The repo shipped only `install.sh` (bash/jq/symlink),
which doesn't run on native Windows PowerShell. Added a PowerShell port.

## What just happened

<!-- verified outcomes only -->
- Created `install.ps1` — PowerShell port of `install.sh` at repo root.
- Ran it end-to-end against a throwaway `$env:CLAUDE_CONFIG_DIR` temp dir: produced correct `settings.json` with `statusLine`, `extraKnownMarketplaces.snovis`, and `enabledPlugins["rsd@snovis"] = true`.
- Verified re-run idempotency: added a custom `permissions` key, re-ran, confirmed it survived and rsd keys stayed correct.
- Cleaned up the temp test dir afterward.

## What's open

- Open: `install.ps1` is written and tested locally but **not yet committed** (this handoff commit will include it). No README update for Windows install instructions yet.
- Reproduce/check by: `powershell -ExecutionPolicy Bypass -File .\install.ps1` from repo root.
- Next likely action: add a Windows section to README.md; optionally add a `node` PATH check to the script and/or guidance on enabling Developer Mode for live symlinks.

## Recent decisions

- 2026-07-07: Use native PowerShell `ConvertFrom-Json`/`ConvertTo-Json` instead of requiring `jq` on Windows · fewer dependencies for Windows users.
- 2026-07-07: Symlink is best-effort with copy fallback · Windows blocks `New-Item -SymbolicLink` without Developer Mode/admin; copy still works but needs re-run after `git pull` to refresh statusline.
- 2026-07-07: Statusline command uses the concrete resolved path, not `$HOME/...` · `$HOME` doesn't expand in cmd.exe where Claude Code runs the statusline on Windows.

## Open threads (not current focus)

- README.md still documents only the `curl | bash` / `install.sh` flow — no Windows instructions.
- Could add a `node --version` preflight check to `install.ps1`.
- Symlink copy-fallback backs up the prior copy to `.backup` on each re-run (harmless, single file, overwritten each time).
