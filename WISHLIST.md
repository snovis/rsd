# rsd Wishlist

Things we've thought of but haven't built. Loose, editable, not a roadmap — just captured so they don't get lost. Each entry is a thread worth pulling sometime.

Add entries freely; delete when built; don't sweat ordering.

---

## Commands

### /rsd:tovault
Promote an existing `.rsd/docs/` entry to a configured vault location *outside* the project — e.g. an Obsidian vault synced via Syncthing. First call asks "where's the vault?", remembers it in `~/.claude/rsd/config.json` (or equivalent), uses it for subsequent promotions.

Default: promotes the most recent doc in `.rsd/docs/`. With an argument: promotes the doc matching that slug or keyword. Optional subfolder arg like `/rsd:tovault area/ember-maintenance` lets the doc land in `ember-vault/area/ember-maintenance/<filename>.md`.

**Why two-step (`/rsd:doc` then `/rsd:tovault`) instead of saving directly to vault:**
- Project-local preservation always happens (cheap, automatic via `/rsd:doc`)
- Elevation to vault is deliberate — not every doc deserves a cross-project home
- Workflow: preserve → review → promote only if valuable

**Real use case that motivated this: multi-Claude reconciliation.**

When working across Claude Desktop (CD) and Claude Code (CC) on the same analysis, both need access to the same source of truth. The vault is the shared medium; Obsidian + Syncthing provides cross-machine availability. Example:
1. CC analyzes the codebase, `/rsd:doc` preserves to `.rsd/docs/`
2. `/rsd:tovault` promotes to `ember-vault/analysis/`
3. Syncthing pushes the vault to desktop
4. CD reads the vault for its own reconciliation pass
5. Differences surface in a follow-up discussion, not in silos

Real-world example: CC saved an analysis to `ember-vault/2-areas/Area - Ember Maintenance/Upstream Merge Analysis - 2026-04-20.md` manually. That path should be one command.

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
The atomic unit of structured multi-step work. A loop is opened, planned, run (iteratively), and closed, producing a small summary.

**Orchestrator / specialist split.** The main session is the orchestrator — it plans, dispatches, receives reports, decides next move. Sub-agents are specialists: one executes in a fresh context (no pollution), another verifies independently (no attachment to what was built). Orchestrator context stays small because expensive tokens live in sub-agents.

**Structure (from Scott's articulation after Layer 0 use):**

1. **Plan** — orchestrator proposes implementation steps; user confirms or adjusts.
2. **Run** (iterative, per task):
   - **Spec** — orchestrator prepares prompt + context + success criteria for the next task.
   - **Pre-dispatch checkpoint** — show the spec to the user, wait for approval. This is the "coworking not fire-and-forget" guarantee at the agent level.
   - **Implement** — dispatch executor agent with the spec. Fresh context.
   - **Verify** — dispatch a *different* agent to check the work. Fresh context, adversarial stance. Structurally separate from implement to prevent self-grading fabrication (the React-form lesson).
   - **Report** — verifier returns pass/fail + notes. Orchestrator reports to user.
   - **Decide** — user accepts, adjusts (update plan, redo task), or abandons.
3. **Close** — all tasks accepted → summary written → loop archived.

**Living plan.** When the verifier reports "this isn't quite right," the plan gets amended before the next iteration — not rewritten, just updated with the change logged. Different from GSD's surgical revision mode; ours is iterative and expected.

**Loop state lives at `.rsd/loops/YYYY-MM-DD-<slug>.md`.** Contains the plan, each iteration's spec + outcome, decisions made, verifier reports. Survives handoff boundaries — a loop in progress travels in HANDOFF.md as an open thread with a pointer to its loop file.

**Commands (tentative):**
- `/rsd:loop <what we're trying to do>` — open a new loop, kick off planning
- `/rsd:loop-step` — advance to next task in the active loop
- `/rsd:loop-close` — finalize and archive the active loop
- Orchestrator auto-handles pre-dispatch checkpoints, verifier runs, report generation.

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

### Validation log + threshold observations

**Run 1** — gnarly upstream merge, step 2. Claude auto-handed-off at 58% (deliberate early test; user would have waited to 70% in normal use). Post-/clear + pickup: 58% → 17%. Compression: 41pt.

**Run 2** — same merge, before step 4. Claude announced: "Context is at 46% — good time to hand off before Step 4. Let me do that now." Nudge fired at 46% (just past 45% threshold), Claude chose a natural break (between steps), announced intent before acting.

**Refined model for the nudge:** informational, not urgent. The 45% threshold surfaces the option; Claude uses judgment about whether there's a sensible break. Between steps = act. Mid-step = defer. This is the right design.

Don't tune thresholds yet. Keep watching. Track compression ratio across handoffs as a health metric (is 30-40pt the norm?).

### Capture real-world validations + regressions
A running log of "what actually happened in production." Each entry: date, situation, outcome, what it taught us. Informs whether thresholds, templates, and behaviors need tuning. Could live at `VALIDATION.md` or inside `.rsd/` once dogfooding starts.
