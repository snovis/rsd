# Handoff

Written: 2026-11-22 08:33 · Context used: (unknown)%
Branch: main · Last commit: 6c7ed67
Durable facts: .rsd/FACTS.md (8 ground-truth entries, 5 solved, 3 dead ends) — read it before building anything not listed under "Next likely action".

## What we're working on

Fixing handoffs that saved conclusions but not reasons. Agents picking up a handoff filled the gaps with confident wrong assumptions and rebuilt things that were already solved. Scott's example: writing a key-reader script when the key was already in a vault the agent could read.

Why: these sophisticated blind alleys burn hours and lots of tokens, and Scott often doesn't catch them until late.

Slice: rsd 0.4.0. Reasons and durable facts in handoffs, plus a pickup tripwire.

## What just happened

- Shipped 0.4.0: new `templates/FACTS.md`, reworked `templates/HANDOFF.md`, `commands/handoff.md`, `commands/pickup.md`, README, version bump — verified by: commit `6c7ed67`, `git push` output `403929f..6c7ed67 main -> main`
- Scott installed it on this Mac — verified by: `/plugin marketplace update snovis` → "1 plugin bumped", `/reload-plugins`, and the `rsd:handoff` skill description now mentions FACTS.md
- This handoff is the first live run of the 0.4.0 spec, and it created this repo's `.rsd/FACTS.md` — verified by: the invocation ran from the `.../rsd/0.4.0/` cache path
- Renaming the handoff sections breaks nothing — verified by: grep of `hooks/` found no section-name parsing

## What's open

- Open: 0.4.0 hasn't been checked in a real project. This self-run only proves the mechanics, because rsd has no vault or secrets problem.
- Reproduce/check by: in the project where the vault-key blind alley happened (which project: [unknown], ask Scott), run `/rsd:handoff` mid-session. Check that `.rsd/FACTS.md` records the vault fact under Ground truth or Solved. Then `/clear` and `/rsd:pickup`, ask for off-path tooling, and confirm the tripwire asks before building.
- Next likely action: wait for Scott's results from that real-project run, then adjust the spec based on what it missed.
- Why that's next: the goal is fewer blind alleys in real work, and only a real project with a known blind alley tests that.
- Out of scope for the next step: more spec changes until a real run shows a gap. Making the handoff slug descriptive is an open thread below, not current work.

## Decisions in force

- 2026-11-22 · chose a separate `.rsd/FACTS.md`, edited in place and never archived · because `HANDOFF.md` is replaced every time and pickup never reads the archive, so facts faded handoff by handoff · rejected a carried-forward section inside HANDOFF.md because every rewrite is another chance to drop it and the 100-line cap pushes toward cuts
- 2026-11-22 · chose "Decisions in force", carried forward until superseded, with because + rejected alternative · because "decisions from this session only" dropped older ones and kept no reasons · rejected having pickup read the archived handoffs because it costs too much context
- 2026-11-22 · chose a session-long tripwire in `pickup.md` (check FACTS, then ask in one line before off-path scripts, credential handling or tooling) · because the failure happens mid-session when the agent picks off-path work · rejected relying on the global CLAUDE.md rules alone, because they already say "ask first" and the failure still happened
- 2026-11-22 · chose version 0.4.0, not 0.3.7 · because it adds a new file format and changes behavior
- 2026-07-07 · chose native PowerShell JSON over `jq` in install.ps1 · because Windows users get fewer dependencies · rejected requiring jq
- 2026-07-07 · chose a best-effort symlink with copy fallback · because Windows blocks symlinks without Developer Mode or admin · rejected requiring symlinks (the copy needs a re-run after `git pull` to refresh the statusline)
- 2026-07-07 · chose the concrete resolved path for the statusline command · because `$HOME` doesn't expand in cmd.exe · rejected `$HOME/...` (not recorded beyond that)

## Open threads (not current focus)

- Handoff slug: with no argument, the spec falls back to an epoch number, so this commit reads `handoff: 1795361634`. Earlier handoffs used descriptive slugs. Consider having the agent choose a short descriptive slug.
- README still has no Windows install section (carried from 2026-07-07).
- `install.ps1` could add a `node --version` preflight check (carried from 2026-07-07).
- `install.ps1` copy fallback overwrites a single `.backup` on each re-run. Harmless (carried from 2026-07-07).
- Engineering notebook (from Scott's global CLAUDE.md): FACTS.md covers part of it, but there's no per-step action/result/lesson log yet.
