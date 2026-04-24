---
name: rsd:walk-done
description: Finalize the active walk. Writes the summary, marks it complete, clears the ACTIVE pointer, commits, and pushes. Use when all items are resolved (or you're ready to stop regardless).
argument-hint: "[optional note]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
---

<objective>
Close out the active walk cleanly. Write a short summary of what the walk accomplished, mark the walk file complete, clear `.rsd/walks/ACTIVE` so the next `/rsd:walk` can run. Non-blocking — finalizes and reports.
</objective>

<principles>
- **Summary is a recap, not a retelling.** 3-5 sentences: what was the walk about, what got done, what was rejected/deferred, anything notable that emerged. Don't list every item.
- **Deferred items don't block completion.** If items are marked `defer`, the walk can still close; the deferred items are noted in the summary for follow-up.
- **Unresolved items do block completion.** If any items are still `— unresolved`, stop and report. User has to either resolve them via `/rsd:next` or explicitly defer them first.
- **One-shot and cheap.** Like handoff and doc — no drama, no interrogation.
</principles>

<process>

1. **Find the active walk.** Walk up from cwd looking for `.rsd/walks/ACTIVE`:

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

   > No active walk to finalize. Start one with `/rsd:walk <description>`.

2. **Read the walk file.** Use the Read tool. Parse:
   - Intent and approach sections
   - Totals from header
   - Each item's status and resolution notes
   - Any flags in `## Flags`

3. **Check for unresolved items.** Count items whose heading still ends in `— unresolved`. If any, stop and report:

   > Walk has <N> unresolved item(s). Finish or defer them first, then run `/rsd:walk-done` again.
   >
   > Remaining: <list of short titles>

   Do NOT finalize a walk with unresolved items.

4. **Synthesize the summary.** 3-5 sentences covering:
   - What the walk was about (from Intent, rephrased for past tense)
   - What got done — not a list of every item, but the net outcome. Call out anything that changed approach mid-walk (amend flags that redirected work).
   - What was rejected or deferred (counts plus a line on why, if notable)
   - Anything that emerged during the walk that's worth remembering (new threads noticed, assumptions that got invalidated)

   Append the optional argument as a user note if provided.

5. **Update the walk file:**
   - Change `Status: in progress` to `Status: complete`.
   - Write the synthesized summary into the `## Summary` section (replace the placeholder comment).
   - Leave item resolutions and Flags as-is — they're the record.

6. **Clear the active pointer:**

   ```bash
   rm "$RSD/walks/ACTIVE"
   ```

7. **Commit and push:**

   ```bash
   git add .rsd/walks/
   git commit -m "walk done: <slug>" --no-verify
   git push 2>/dev/null || true
   ```

8. **Report briefly** — one or two lines:

   ```
   Walk closed: <slug> (<done> done · <rejected> rejected · <deferred> deferred · <modified> modified).
   Summary written to .rsd/walks/<file>. Ready for the next walk.
   ```

</process>

<guardrails>
- **Never finalize with unresolved items.** Stop and report. User must resolve or defer them first.
- **Never fabricate summary content.** Summary comes from the walk file's actual resolutions and flags. If the walk was empty-feeling, the summary says so honestly.
- **Never skip clearing `.rsd/walks/ACTIVE`.** Without this, the next `/rsd:walk` blocks.
- **Never block on push failures.** Commit stands even if push fails.
- **Never re-open a closed walk.** If a walk is already complete, report that fact and exit.
</guardrails>

<success>
- Walk file has `Status: complete` and a substantive `## Summary` section.
- `.rsd/walks/ACTIVE` has been removed.
- Git commit created (`walk done: <slug>`).
- Push attempted.
- One-line report to user.
</success>
