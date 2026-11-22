---
name: rsd:pickup
description: Read the latest handoff and brief the current session on where we are. Use after /clear, on resume, or any time you've forgotten what we were doing.
argument-hint: ""
allowed-tools:
  - Read
  - Bash
  - Glob
---

<objective>
Resume cleanly from the last handoff. Read `.rsd/HANDOFF.md`, surface the key points to the user in a single brief response, and be ready for the next instruction.
</objective>

<principles>
- **Fast.** The user wants to know "what are we working on?" — answer that in a few lines, not a dissertation.
- **Honest.** If a handoff is stale (hours or days old), say so. If `What's open` looks incomplete, say so.
- **No re-asking.** The handoff is the source of truth. Don't re-interrogate the user about decisions already logged.
- **Tee up, don't execute.** Pickup briefs the user and waits. It does not start the next work unprompted.
- **Unknown is not unsolved.** If the handoff doesn't mention something, that means *this file* doesn't say — not that nobody has solved it. Check `.rsd/FACTS.md`, then ask the user. Never fill the gap with a guess and build on it.
</principles>

<process>

1. **Find the handoff.** Run one command to locate the project root:
   ```bash
   git rev-parse --show-toplevel
   ```
   The handoff lives at `<root>/.rsd/HANDOFF.md` — use the returned path as an absolute prefix for every file operation below. If that command errors (not a git repo), fall back to `.rsd/HANDOFF.md` in the current working directory.

   If no handoff file exists, ask the user once: "I don't see a `.rsd/HANDOFF.md` at the project root. Are we in a new project, or should I look somewhere else?" Wait for a response; don't guess.

2. **Check the remote for a newer handoff.** The user may have handed off from another machine and forgotten to pull. Run:
   ```bash
   git fetch
   ```
   If the fetch fails (no remote, offline), skip this step silently. Otherwise:
   ```bash
   git rev-list --left-right --count @{upstream}...HEAD
   ```
   Output is `<behind>	<ahead>` (errors → no upstream, skip). If behind > 0, check the working tree:
   ```bash
   git status --porcelain
   ```
   - **Clean tree:** fast-forward before reading, so the brief reflects the latest handoff:
     ```bash
     git pull --ff-only
     ```
     If it succeeds, note `pulled <behind> commits from remote` for the brief. If it fails (diverged), don't force anything — read the local handoff and flag the divergence in the brief.
   - **Dirty tree:** don't pull over uncommitted work. Read the local handoff and lead the brief with a warning: `⚠ Remote is <behind> commits ahead (likely a handoff from another machine) but this tree has uncommitted changes — reconcile before trusting this brief.`

3. **Read the handoff and the facts file with the Read tool.** The whole handoff; it should be short. Then Read `<root>/.rsd/FACTS.md` if it exists — the whole file. It holds the durable ground truth (where keys live, how to deploy, what access you already have), what's already solved, and the dead ends. Keep it in mind for the rest of the session; the tripwire below depends on it. If it doesn't exist, note `no FACTS.md yet` for the brief.

4. **Check freshness.** Compare the handoff's `Written:` header line to the current time to qualify the report ("written 12 minutes ago" vs "written 3 days ago"). If you need the current time, run one command:
   ```bash
   date
   ```

5. **Check for active walk** (belt-and-suspenders — the handoff *should* mention it, but read directly to guarantee surfacing). Use the Read tool on `<root>/.rsd/walks/ACTIVE`. If that file exists, its contents name the active walk file — Read `<root>/.rsd/walks/<name>` with the Read tool. Note:
   - Total items and resolved count
   - Current item number + short title (first `— unresolved` heading)
   - Any flags on that current item

6. **Report to the user** — one compact message, roughly this shape:

   ```
   Picked up handoff (written <age>, context was at <pct>%<, pulled N commits from remote if applicable>).

   **We're working on:** <one line from "What we're working on">

   **Active walk:** <slug> · <K> of <N>, on item <M>: <title>. `/rsd:next` to resume.
   <only include this line if an active walk exists>

   **Last verified:** <top 2 bullets from "What just happened">

   **Open:** <the "Open" line from "What's open">
   **Next likely:** <the "Next likely action" line> — <the "Why that's next" line>

   <N> decisions in force, <M> open threads parked. Facts: <G> ground truth, <S> solved, <D> dead ends<, or "no FACTS.md yet">.

   Ready when you are.
   ```

   Keep it under ~15 lines. Don't recap everything — the handoff file is still on disk if the user wants the rest. If the handoff's "What's open" already contained walk context (pointer + discussion summary), don't repeat it verbatim; the one-line "Active walk:" suffices and the rest is in the handoff.

7. **Stop.** Do not proceed to the next work until the user tells you to.

</process>

<tripwire>
This applies for the **whole session** after pickup, not just the brief.

Before starting work that doesn't trace directly to the handoff's "Next likely action" — and **always** before writing new scripts, auth or credential handling, key readers, installers, or other tooling/infrastructure:

1. Check `.rsd/FACTS.md` (Ground truth, Solved, Dead ends) and the handoff's Decisions in force. If the problem is already solved there, use that solution. If the approach is listed as a dead end, don't take it.
2. If it isn't covered, ask the user in one line before building — name what you were about to build and the assumption behind it. Example: `Before I write a key-reader script: is there already a way to get the API key (vault, env, secret store)? FACTS.md doesn't say.`
3. When the user answers, the answer is durable — the next `/rsd:handoff` must record it in `.rsd/FACTS.md`.

A one-line question costs seconds. A sophisticated blind alley costs hours and is often caught too late.
</tripwire>

<guardrails>
- **Never invent details.** If the handoff is missing a section or has a `{{template}}` placeholder, report it as missing — don't fabricate.
- **Never merge prior context.** Your job is to load the handoff, not combine it with earlier chatter.
- **Stale handoffs deserve a flag.** If age > 24 hours, note it explicitly — the user may have forgotten context.
- **Never treat a gap as permission to invent.** A decision with `(not recorded)` as its reason, or an `[inferred]`/`[unknown]` fact, is a question for the user, not a premise to build on.
</guardrails>

<success>
- Remote checked (`git fetch` + behind/ahead); a newer remote handoff pulled when safe, or the divergence/dirty-tree flagged in the brief.
- Handoff located and read; `.rsd/FACTS.md` read if present.
- Active walk (if any) detected via `.rsd/walks/ACTIVE` and surfaced in the brief with slug, progress, and current item.
- User briefed in a short message covering focus, last verified, open thread, and next likely action.
- Age and decision/thread counts disclosed.
- Session waits for user input. No autonomous continuation.
</success>
