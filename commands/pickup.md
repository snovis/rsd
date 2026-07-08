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
</principles>

<process>

1. **Find the handoff.** Run one command to locate the project root:
   ```bash
   git rev-parse --show-toplevel
   ```
   The handoff lives at `<root>/.rsd/HANDOFF.md` — use the returned path as an absolute prefix for every file operation below. If that command errors (not a git repo), fall back to `.rsd/HANDOFF.md` in the current working directory.

   If no handoff file exists, ask the user once: "I don't see a `.rsd/HANDOFF.md` at the project root. Are we in a new project, or should I look somewhere else?" Wait for a response; don't guess.

2. **Read the handoff with the Read tool.** The whole file; it should be short.

3. **Check freshness.** Compare the handoff's `Written:` header line to the current time to qualify the report ("written 12 minutes ago" vs "written 3 days ago"). If you need the current time, run one command:
   ```bash
   date
   ```

4. **Check for active walk** (belt-and-suspenders — the handoff *should* mention it, but read directly to guarantee surfacing). Use the Read tool on `<root>/.rsd/walks/ACTIVE`. If that file exists, its contents name the active walk file — Read `<root>/.rsd/walks/<name>` with the Read tool. Note:
   - Total items and resolved count
   - Current item number + short title (first `— unresolved` heading)
   - Any flags on that current item

5. **Report to the user** — one compact message, roughly this shape:

   ```
   Picked up handoff (written <age>, context was at <pct>%).

   **We're working on:** <one line from "What we're working on">

   **Active walk:** <slug> · <K> of <N>, on item <M>: <title>. `/rsd:next` to resume.
   <only include this line if an active walk exists>

   **Last verified:** <top 2 bullets from "What just happened">

   **Open:** <the "Open" line from "What's open">
   **Next likely:** <the "Next likely action" line>

   <N> decisions on file, <M> open threads parked.

   Ready when you are.
   ```

   Keep it under ~15 lines. Don't recap everything — the handoff file is still on disk if the user wants the rest. If the handoff's "What's open" already contained walk context (pointer + discussion summary), don't repeat it verbatim; the one-line "Active walk:" suffices and the rest is in the handoff.

6. **Stop.** Do not proceed to the next work until the user tells you to.

</process>

<guardrails>
- **Never invent details.** If the handoff is missing a section or has a `{{template}}` placeholder, report it as missing — don't fabricate.
- **Never merge prior context.** Your job is to load the handoff, not combine it with earlier chatter.
- **Stale handoffs deserve a flag.** If age > 24 hours, note it explicitly — the user may have forgotten context.
</guardrails>

<success>
- Handoff located and read.
- Active walk (if any) detected via `.rsd/walks/ACTIVE` and surfaced in the brief with slug, progress, and current item.
- User briefed in a short message covering focus, last verified, open thread, and next likely action.
- Age and decision/thread counts disclosed.
- Session waits for user input. No autonomous continuation.
</success>
