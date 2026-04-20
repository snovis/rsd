# rsd Wishlist

Things we've thought of but haven't built. Loose, editable, not a roadmap — just captured so they don't get lost. Each entry is a thread worth pulling sometime.

Add entries freely; delete when built; don't sweat ordering.

---

## Commands

### /rsd:vault
Save an analysis (like `/rsd:doc`) but to a configured vault location *outside* the current project — e.g. an Obsidian vault synced via Syncthing or similar. First call asks "where's the vault?", remembers it in `~/.claude/rsd/config.json` (or equivalent), uses it for subsequent saves. Supports optional subfolder argument like `/rsd:vault area/ember-maintenance "upstream merge analysis"` so the doc lands in `ember-vault/area/ember-maintenance/upstream-merge-analysis-2026-04-20.md`.

Useful for cross-project knowledge accumulation where the material isn't tied to a single repo.

Real-world example that motivated this: CC saved an analysis to `ember-vault/2-areas/Area - Ember Maintenance/Upstream Merge Analysis - 2026-04-20.md` where it syncs to Obsidian via Syncthing. That pattern should be one command, not manual.

### /rsd:docs
List the preserved docs in the current project's `.rsd/docs/`. With a keyword argument, filter by title match. Useful for "what did we analyze last week?" without shelling out.

### /rsd:status
Compact status readout: current branch, handoff freshness, count of docs/decisions/threads, context usage. A kind of "where am I" one-shot. Probably also runs automatically at session start via a SessionStart hook so you always see it.

---

## Pickup enhancements

### Include doc count in the brief
When `/rsd:pickup` reports, mention how many preserved docs exist in `.rsd/docs/` alongside decisions and threads count. So the brief might say: "3 docs on file, 5 decisions logged, 4 threads parked."

### Surface stale handoff warning
If the handoff being picked up is more than 24h old, lead with that. "Picked up handoff from 3 days ago — likely out of date. Review before continuing."

---

## Safety + correctness

### Pin .rsd/ to project root
Currently `/rsd:handoff` walks up looking for `.rsd/`, but if missing, the spec is vague about where to create the new one. Refine: walk up looking for `.git/`, create `.rsd/` as its sibling. Pins `.rsd/` to project root deterministically.

### Confirm .rsd/ creation outside a git repo
If there's no `.git/` in the walk-up chain, `/rsd:handoff` should confirm with the user before creating `.rsd/` in cwd. Otherwise running it from `~/` would create `~/.rsd/` by accident.

### Validate command frontmatter fields
Check whether `argument-hint` and `allowed-tools` in command frontmatter are honored by the current Claude Code plugin system or silently ignored. Strip them if deprecated; keep if honored. Right now they're present because GSD used them, but the current docs don't mention them for commands.

### Self-check on handoff
The handoff already has a `<self_check>` mindset baked into the prompt ("verified outcomes only"). Could go further: after writing HANDOFF.md, re-read it and confirm every claim in "What just happened" is traceable to a commit or observable state. Reject the handoff if any bullet is a fabrication.

---

## Distribution + updates

### Auto-update marketplace on session start
A `SessionStart` hook could run `claude plugin marketplace update snovis` once per day (or per session) so remote machines stay current without manual intervention. Configurable with a `user_config.auto_update` flag.

### curl | bash install one-liner
A simple bootstrap script at `raw.githubusercontent.com/snovis/rsd/main/bootstrap.sh` that git-clones rsd to `~/dev/rsd/` and runs `./install.sh` in one command. Makes remote install a single line.

### Seed directory support
For containerized/CI environments, document or test `CLAUDE_CODE_PLUGIN_SEED_DIR` usage so rsd can be pre-installed into images without runtime cloning.

---

## Future layers (not Layer 0 scope)

### Layer 1: loop envelope
The cowork → implement → verify → feedback cycle as structured commands. A loop is opened, worked, and closed, producing a small summary that rolls up into the active slice. This is the atomic unit; everything else composes from it.

### Layer 2: slice wrapper
Orchestrates multiple loops within a single session. Carries state up when the session ends. Links loops to the slice they belong to.

### Layer 3: area + intent
The tree: project intent at the top, areas as known regions of work, slices beneath them. STATE.md becomes multi-level. Pickup can traverse the tree to give richer context.

### Layer 4: specialist subagents
Ported from GSD: planner, executor, verifier, researcher. Each invoked per-loop with a pre-dispatch human checkpoint (not fire-and-forget).

---

## Meta

### Dogfood rsd on rsd itself
Initialize `.rsd/` in this repo. Use rsd to track rsd's own development. Every slice of rsd development = one handoff. Every substantial design conversation = one doc. This wishlist moves into `.rsd/threads.md` once that level exists.

### Tune nudge thresholds based on real use
First real-world validation (gnarly upstream merge, step 2): Claude auto-handed-off at 58% context. Post-/clear + pickup dropped context to 17% — a 41-point compression. The 58% was a deliberate early test; the user would have waited until ~70% in normal use.

Implication: the 45% nudge may be over-eager. Worth watching whether the nudges feel like noise in practice. Possible tuning:
- Raise the first nudge from 45% to something like 55-60%
- Keep 75% as the "strongly recommend" threshold
- Track compression ratio across handoffs as a health metric (is 30-40pt the norm?)

Single data point — don't change thresholds yet. Accumulate a few more observations first.

### Capture real-world validations + regressions
A running log of "what actually happened in production." Each entry: date, situation, outcome, what it taught us. Informs whether thresholds, templates, and behaviors need tuning. Could live at `VALIDATION.md` or inside `.rsd/` once dogfooding starts.
