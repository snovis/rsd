# rsd

**R**ymare **S**oftware **D**evelopment — cold-start-ready handoffs for Claude Code.

Call `/rsd:handoff` anytime. `/clear`. Then `/rsd:pickup`. The next Claude reads where you left off and keeps going. No re-interrogation, no re-discovery, no "where were we?"

```
mac-mini │ Opus 4.7 │ Building auth │ myproj (main●) │ H:12m █████░░░░░ 48%
```

## What's in Layer 0

The minimum useful set. Handoffs only. No planner, no executor, no phase concepts. Just a reliable save/resume primitive that works every time.

- **`/rsd:handoff`** (shortcut `/rsd:ho`) — write `.rsd/HANDOFF.md`, archive the previous one, commit, push. Non-blocking: call any time, keep working after.
- **`/rsd:pickup`** (shortcut `/rsd:pu`) — read the handoff and brief the current session. Use after `/clear`, on resume, or any time you've forgotten what you were doing.
- **Statusline** — host · model · current task · directory (branch) · handoff freshness · context bar. Gracefully degrades in projects without `.rsd/`.
- **Context monitor** — proactive nudge around 45/60/75% ("consider `/rsd:handoff`") so you don't hit auto-compact by surprise.

## Install

```bash
git clone https://github.com/snovis/rsd.git ~/dev/rsd
cd ~/dev/rsd
./install.sh
```

That's it. Restart Claude Code; `/rsd:handoff` and friends work in any git project. The installer does two things:

**Statusline:** Symlinks `hooks/statusline.js` into `~/.claude/hooks/` and patches `~/.claude/settings.json` to register it. Any existing `statusLine` entry is preserved under `statusLine_backup`.

**Plugin:** Patches `~/.claude/settings.json` with `extraKnownMarketplaces.snovis` (pointing at `github.com/snovis/rsd`) and `enabledPlugins["rsd@snovis"]: true`. Claude Code clones the plugin into its cache on first launch and auto-loads it every session after.

Requires `jq` on PATH (`brew install jq` on macOS; `apt-get install jq` on Debian/Ubuntu).

After restart, verify with:

```
/plugin marketplace list    # should list "snovis"
/plugin list                # should show "rsd@snovis" enabled
/rsd:handoff                # try it
```

### Dev mode

If you're hacking on rsd itself, override the cached version with the local clone:

```bash
claude --plugin-dir ~/dev/rsd
```

The local copy takes precedence over the installed version for that session. Handy for iterating on command prompts or hooks without waiting for a release.

### Remote machines

Same flow: clone the repo, run `./install.sh`. Updates to published rsd are pulled via:

```
/plugin marketplace update snovis
```

## The handoff file

Every handoff writes `.rsd/HANDOFF.md` in the project root. Archives land in `.rsd/handoffs/YYYY-MM-DD-HHmm-<slug>.md`. Both are committed and pushed (best-effort).

Shape:

- **What we're working on** — 1-3 sentences of honest focus.
- **What just happened** — 3-5 verified outcomes. Things that actually ran, rendered, or passed.
- **What's open** — the specific unfinished thread, with reproduction steps and next likely action. Cold-start readable.
- **Recent decisions** — provisional, dated, never locked.
- **Open threads** — loose list of things noticed but deferred.

The file is written for a fresh Claude, not for you. You already know what happened.

## Principles

Handoffs should be **cheap to call**. Calling `/rsd:handoff` five times in a session costs nothing — no interrogation, no long summaries, no "are you sure?". The pattern is `handoff → keep working → handoff again` as much as `handoff → clear → pickup`.

Verified outcomes only. If a task wasn't actually verified (the React page rendered, the test passed, the API returned the expected response), it belongs in "What's open," not "What just happened."

Nothing is locked. Decisions are dated and revisitable. Handoffs are provisional by design — the point is to resume cleanly, not to create a contract.

## Roadmap

Layer 0 is intentionally small. Future layers introduce (maybe):

- **Layer 1** — the loop envelope (cowork → implement → verify → feedback).
- **Layer 2** — slice orchestration.
- **Layer 3** — area / intent / tree navigation.
- **Layer 4** — specialist subagents with pre-dispatch checkpoints.

Each layer gets built only when the layer below is stable. If Layer 0 is enough, we stop at Layer 0. Pixar rule: iterate in the cheapest useful medium.

## Attribution

The context-bar rendering and auto-compact normalization originated in [obra/superpowers](https://github.com/obra/superpowers) / the [`get-shit-done`](https://github.com/gsd-build/get-shit-done) plugin's statusline, which was extracted into the standalone [`rymare-cli-bar`](https://github.com/scottnovis/rymare-cli-bar). The rsd statusline extends that with `.rsd/` handoff awareness.

## License

MIT
