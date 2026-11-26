---
name: rsd:pickup
description: Read the latest handoff and brief the current session on where we are. In a project with roles (.rsd/ROLES.md), `/rsd:pickup <role>` reads that role's own handoff. Use after /clear, on resume, or any time you've forgotten what we were doing.
argument-hint: "[role]"
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

   If `<root>/.rsd/HANDOFF.md` does not exist, do step 1b before concluding anything: the project may keep one handoff per role instead. Only if step 1b finds no role handoffs either, ask the user once: "I don't see a `.rsd/HANDOFF.md` at the project root. Are we in a new project, or should I look somewhere else?" Wait for a response; don't guess.

1b. **Work out which handoff is this session's.** Some projects run more than one Claude session at once, each with its own role and its own handoff file, `<root>/.rsd/HANDOFF-<role>.md`. Read `<root>/.rsd/ROLES.md` with the Read tool. It declares the roles, one per line (`- forge · commits: yes · the build session`).

   - **No `ROLES.md`, and no argument:** the project has no roles. The handoff is `<root>/.rsd/HANDOFF.md`, and everything below works as written. Skip the rest of this step.
   - **An argument was given:** the role is its first word, lowercased.
     - If `<root>/.rsd/HANDOFF-<role>.md` exists, that is the handoff. Every later step reads it in place of `HANDOFF.md`.
     - If it does not exist but the role is declared and a plain `<root>/.rsd/HANDOFF.md` does: the role has not handed off yet. Read the plain one and open the brief with `No handoff for <role> yet, so this is the project's shared handoff from before roles.`
     - Otherwise there is nothing by that name. Do not fall back in silence: list the handoff files that do exist (Glob `<root>/.rsd/HANDOFF*.md`) and the roles `ROLES.md` declares, and ask the user once which one they meant.
   - **Roles exist and no argument was given:** if this session already knows its role (it was told "you are Forge", or it picked up as a role earlier), use that role. If it does not, never guess: list each role's handoff with its `Written:` time and ask once, `This project has role handoffs: forge (written 10 minutes ago), muse (written 2 hours ago). Which role is this session?`

   Once the role is known, **this session is that role until told otherwise.** A later `/rsd:handoff` with no role writes this role's handoff. Note the role's `commits:` setting from `ROLES.md` for step 2.

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
   - **A role declared `commits: no`** never pulls, clean tree or not: it does not change git. If behind > 0, read the local handoff and lead the brief with: `⚠ Remote is <behind> commits ahead and <role> does not pull. Have the committing session pull (or run git pull yourself) before trusting this brief.`

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

   **With a role**, the first line names it and its file, and one line before "Ready when you are." names the other roles so the session knows they exist:

   ```
   Picked up forge's handoff, .rsd/HANDOFF-forge.md (written <age>, context was at <pct>%).
   ...
   Other roles here: muse (handoff written <age>). Their handoffs are theirs; I have not read them.
   ```

   If another role has no handoff file yet, say `muse (no handoff yet)`. Get each age from the `Written:` line near the top of that role's file (Read with a limit of a few lines) and read no further: another role's handoff is another session's context.

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
- **Never pick up another role's handoff as your own.** With roles, load only the handoff of the role this session is. If the role is not known, ask; a wrong guess hands one session the other's job.
</guardrails>

<success>
- Remote checked (`git fetch` + behind/ahead); a newer remote handoff pulled when safe, or the divergence/dirty-tree flagged in the brief.
- Handoff located and read; `.rsd/FACTS.md` read if present.
- Active walk (if any) detected via `.rsd/walks/ACTIVE` and surfaced in the brief with slug, progress, and current item.
- User briefed in a short message covering focus, last verified, open thread, and next likely action.
- Age and decision/thread counts disclosed.
- Session waits for user input. No autonomous continuation.
- In a project with `.rsd/ROLES.md`: the role's own `.rsd/HANDOFF-<role>.md` read (or the fallback said out loud), the brief names the role and the other roles, and a `commits: no` role pulled nothing.
</success>
