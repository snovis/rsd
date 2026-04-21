---
name: rsd:next
description: Resolve the current walk item and advance to the next one. Runs an amend pass — flags remaining items that may have been affected by the fix.
argument-hint: "<done|reject|defer|modify> [notes]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
---

<objective>
Move the active walk forward by one step: log the resolution for the current item, run an amend pass over remaining items, surface the next unresolved item. Non-blocking — just advances the cursor and keeps the conversation flowing.
</objective>

<principles>
- **One step at a time.** Resolve current, surface next, stop. No batch advancement.
- **Explicit resolution.** Require one of `done | reject | defer | modify`. Don't infer from chat.
- **Amend, don't rewrite.** After a resolution, read remaining items through the lens of what just changed. Flag anything that looks affected. Never silently edit a later item.
- **Honest about gaps.** If the fix is claimed but not actually verified, say so in the notes. Walks inherit the handoff principle: verified outcomes only.
</principles>

<process>

1. **Find the active walk.** Walk up from cwd to find `.rsd/walks/ACTIVE`:

   ```bash
   DIR=$(pwd)
   while [ "$DIR" != "/" ]; do
     if [ -f "$DIR/.rsd/walks/ACTIVE" ]; then
       RSD="$DIR/.rsd"
       ACTIVE=$(cat "$RSD/walks/ACTIVE")
       WALK="$RSD/walks/$ACTIVE"
       break
     fi
     DIR=$(dirname "$DIR")
   done
   ```

   If no active walk, stop and report:

   > No active walk. Start one with `/rsd:walk <description>`.

2. **Parse the argument.** Expected shape: `<status> [notes]` where status is one of `done`, `reject`, `defer`, `modify`. The rest of the argument is free-text notes. If no argument or status is missing/invalid, stop and report:

   > Usage: `/rsd:next <done|reject|defer|modify> [notes]`
   > Current item is still unresolved.

   Re-surface the current item so the user can see what they're deciding on.

3. **Read the walk file.** Use the Read tool. Identify the current item — the first item whose heading ends in `— unresolved`. If every item is resolved or deferred, skip to step 7 (nothing to resolve, just report state).

4. **Update the current item in the walk file.** Use Edit:
   - Change the heading from `### N. <title> — unresolved` to `### N. <title> — <status>`
   - Fill in the `**Resolution**` block: `<status> · <notes>` (or just `<status>` if no notes).
   - Append to `**Discussion**` if there are substantive notes worth keeping alongside the terse resolution. Keep it brief — the resolution line is the record of truth.
   - Update the header totals line (increment the appropriate counter, decrement `unresolved`).

5. **Amend pass.** Read the remaining unresolved items. For each, ask: *did the resolution just logged (especially if `done` or `modify`) change the ground the remaining items stand on?* Common signals:
   - The fix touched the same file or config key a later item references
   - The fix makes a later item moot or redundant
   - The fix revealed a deeper issue that reframes a later item

   For any flagged item, append a note to the `## Flags` section of the walk file:

   ```
   - item N: <why flagged> · raised after item <current> resolved
   ```

   Do **not** rewrite the item itself. Just flag it. The user decides what to do when the walk reaches that item.

6. **Commit:**

   ```bash
   git add .rsd/walks/
   git commit -m "walk: item <N> <status>" --no-verify
   git push 2>/dev/null || true
   ```

7. **Surface the next item (or wrap up).** Find the next `— unresolved` item. Two cases:

   **If there's a next item**, report:

   ```
   Item <N> logged: <status><notes-if-any>.
   [<M> items remain · <K> flagged for re-check if any]

   **On item <N+1>:** <short title>

   <recommendation text>

   [Flags on this item: <why>] (if flagged during amend pass)
   ```

   **If no items remain unresolved** (everything is done/rejected/modified; deferred items may still exist):

   ```
   Item <N> logged: <status>.
   All items resolved (<done> done · <rejected> rejected · <modified> modified · <deferred> deferred).
   `/rsd:walk-done` to finalize, or revisit deferred items first.
   ```

</process>

<guardrails>
- **Never advance without an explicit status.** Missing or invalid → error and re-surface current item. Do not guess from conversation.
- **Never auto-rewrite a later item during amend.** Flags only. The user drives edits.
- **Never mark `done` if the fix wasn't verified.** If the user says "done" but nothing was actually run/tested, push back once: "Was this verified, or should we log it as `modify` with a note?" Still respect their call if they insist.
- **Never block on push failures.** Commit stands even if push fails.
- **If the current item is flagged from a prior amend pass**, surface that flag when re-presenting the item so the user sees it before deciding.
</guardrails>

<success>
- Current item in `.rsd/walks/<active>.md` updated with resolution and timestamp-free note.
- Header totals reflect the new counts.
- Amend pass run; any affected remaining items added to `## Flags`.
- Git commit created (`walk: item <N> <status>`).
- Next unresolved item surfaced, or wrap-up message if none remain.
- Session waits for discussion on the next item.
</success>
