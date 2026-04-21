---
name: rsd:walk
description: Start a walk — a living tasklist you step through one item at a time via /rsd:next. Captures the items from recent conversation (with confirmation) or from the argument.
argument-hint: "<what this walk is about>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
---

<objective>
Capture a list of items (recommendations, todos, review comments) as a durable artifact you can walk through one at a time. Non-blocking discussion/fix/amend is the core loop; this command just opens the walk and surfaces the first item.
</objective>

<principles>
- **Living, not frozen.** A walk is expected to change mid-flight. Items get added, dropped, or reworded as the walk surfaces things. The list captured at start is a snapshot, not a contract.
- **One at a time.** The walk only ever surfaces one item as "current." The rest are visible in the file but not in your face.
- **Explicit items.** If no recent list exists in conversation, ask the user to provide one. Don't invent items.
- **Cheap to start.** Opening a walk is the same cost profile as /rsd:handoff or /rsd:doc — no drama, no long prep.
</principles>

<process>

1. **Require an argument.** If invoked with no argument, stop and ask:

   > What's this walk about? e.g. `/rsd:walk review Opus recommendations for context-monitor`

   Wait for a response. Do not proceed without an explicit description.

2. **Check for an active walk.** Read `.rsd/walks/ACTIVE` if it exists. If it points to a walk with unresolved items, stop and report:

   > Active walk already open: `<file>` (<N> of <M> resolved). Finish with `/rsd:walk-done` or continue via `/rsd:next` before starting a new one.

   Do not silently overwrite an in-flight walk.

3. **Walk up from cwd to find `.rsd/`** (prefer sibling of `.git/`). Create `.rsd/walks/` if missing:

   ```bash
   mkdir -p .rsd/walks
   ```

4. **Capture metadata:**

   ```bash
   STAMP=$(date +"%Y-%m-%d-%H%M")
   BRANCH=$(git branch --show-current 2>/dev/null || echo "(none)")
   COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "(none)")
   ```

5. **Generate slug** from the argument — lowercase, hyphens, strip punctuation. Under 40 chars.

6. **Gather the items.** Two paths:

   **A. Extract from recent conversation.** If the conversation contains a numbered or bulleted list of recommendations/todos that matches the walk's description, extract those items verbatim. Then confirm with the user:

   > I count N items. Does this look right?
   > 1. <short title>
   > 2. <short title>
   > ...

   Wait for yes / corrections. If the user says "use items 1, 3, 5" or "add this other one," adjust and re-confirm.

   **B. Ask for the items.** If no list exists in recent conversation, say so and wait:

   > I don't see a list in recent conversation. Paste the items (numbered or bulleted) and I'll capture them.

   Do not fabricate items. Do not use a guessed list.

7. **Write `.rsd/walks/${STAMP}-${SLUG}.md`** using the shape at `@${CLAUDE_PLUGIN_ROOT}/templates/WALK.md`. Each item gets:
   - A heading `### N. <short title> — unresolved`
   - `**Recommendation**` — the verbatim item text (including rationale if present)
   - `**Discussion**` — empty placeholder
   - `**Resolution**` — empty placeholder

   Header totals: N total, 0 done/rejected/deferred/modified, N unresolved.

8. **Mark the walk active.** Write the relative filename (just `${STAMP}-${SLUG}.md`, not the full path) to `.rsd/walks/ACTIVE`:

   ```bash
   echo "${STAMP}-${SLUG}.md" > .rsd/walks/ACTIVE
   ```

9. **Commit and push** (single atomic commit):

   ```bash
   git add .rsd/walks/
   git commit -m "walk start: ${SLUG}" --no-verify
   git push 2>/dev/null || true
   ```

10. **Surface the first item and report.** Brief format:

    ```
    Walk started: <N> items captured in `.rsd/walks/<file>`.

    **On item 1:** <short title>

    <recommendation text>

    Discuss when ready. `/rsd:next <done|reject|defer|modify> [notes]` to advance.
    ```

    Keep it compact. The user can Read the walk file if they want the whole list.

</process>

<guardrails>
- **Never fabricate items.** If the conversation has no list, ask. Don't guess.
- **Never silently overwrite an active walk.** If `.rsd/walks/ACTIVE` exists and points to a walk with unresolved items, stop and report.
- **Never ask interrogation questions about decisions.** The walk is for logging decisions as they happen, not pre-deciding them.
- **Never block on push failures.** Commit stands even if push fails; note it in the one-line report.
- **The argument is required.** Missing → ask and wait.
</guardrails>

<success>
- `.rsd/walks/YYYY-MM-DD-HHmm-<slug>.md` exists with items captured verbatim.
- `.rsd/walks/ACTIVE` points to the new walk file.
- Git commit created (`walk start: <slug>`).
- Push attempted.
- First item surfaced to user; session waits for discussion.
</success>
