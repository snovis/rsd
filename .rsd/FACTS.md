# Project facts

<!--
Durable. This file is NEVER archived or overwritten by a handoff — it is edited in place.
It holds what a fresh Claude would otherwise rediscover, guess at, or rebuild.

Rules:
- Every entry carries a status: [verified] (ran it / saw it, say how), [inferred] (reasoned, not checked), [unknown] (open question).
- Add the *why* and *how we know*, not just the conclusion. One or two lines per entry.
- Never delete an entry silently. If something is contradicted, move it to "Retired" with the date and what contradicted it.
- No secret VALUES here. Say where a secret lives and how to read it, never the secret itself.
-->

Last updated: 2026-11-22 08:33

## Ground truth

- [verified] This repo IS the rsd plugin source. Publishing = `git push` to `main` on github.com/snovis/rsd (the `snovis` marketplace). Nothing auto-installs; machines pull it. — how we know: 0.4.0 push, then user's `/plugin marketplace update snovis` reported "1 plugin bumped" (2026-11-22)
- [verified] Plugin version lives only in `.claude-plugin/plugin.json`. `marketplace.json` has no version field. — how we know: read both files (2026-11-22)
- [verified] Installed copy runs from `~/.claude/plugins/cache/snovis/rsd/<version>/`. — how we know: `/rsd:ho` invocation this session pointed at `.../rsd/0.4.0/commands/handoff.md` (2026-11-22)
- [inferred] That cache is shared by every session on the machine, so other running sessions only need `/reload-plugins` (no marketplace update). — how we know: single per-user cache path; not yet observed in a second session (2026-11-22)
- [verified] A PreToolUse hook enforces Scott's shell rules strictly: rejects `;` `&&` `||` anywhere in the command, including inside a quoted commit message, and rejects multi-line commands. — how we know: two rejected `git commit -m` attempts (2026-11-22)
- [verified] No hook parses HANDOFF.md section names — renaming sections is safe. — how we know: grep of `hooks/` for section names found nothing (2026-11-22)
- [verified] On Windows, `$HOME` does not expand in cmd.exe, which is where Claude Code runs the statusline command — use the concrete resolved path. — how we know: carried from 2026-07-07 handoff decision (install.ps1 work)
- [verified] On Windows, `New-Item -SymbolicLink` fails without Developer Mode or admin. — how we know: carried from 2026-07-07 handoff (install.ps1 work)

## Solved — don't redo

- Test changed rsd commands without losing the live session → `git push`, then `/plugin marketplace update snovis`, then `/reload-plugins` → README "Remote machines" section (2026-11-22)
- Commit message with punctuation/newlines blocked by the shell hook → Write the message to a scratchpad file, then `git commit -F <file>` (2026-11-22)
- Cross-machine handoff clobbering → handoff and pickup fetch + compare behind/ahead before writing → `commands/handoff.md` step 3, `commands/pickup.md` step 2 (0.3.6)
- Windows install → `install.ps1` (native PowerShell JSON, symlink with copy fallback), tested against a temp `CLAUDE_CONFIG_DIR` → repo root (2026-07-07)
- Facts and reasons decaying across handoffs → this file + "Decisions in force" carry-forward + pickup tripwire → 0.4.0, `templates/FACTS.md` (2026-11-22)

## Dead ends — tried, didn't work

- `git commit -m "..."` with a `;` in the text, or multiple `-m` / embedded newlines → shell hook rejects it. Use `-F` with a file. (2026-11-22)
- Suggesting `claude --plugin-dir ~/dev/rsd` to test changes mid-session → requires a fresh launch, which wipes the session's context. Fine for a cold dev session only. (2026-11-22)
- Requiring `jq` on Windows → rejected as an extra dependency; native `ConvertFrom-Json`/`ConvertTo-Json` instead. (2026-07-07)

## Retired

- (none)
