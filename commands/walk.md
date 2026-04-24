---
name: rsd:walk
description: Start a walk — a living tasklist you step through one item at a time via /rsd:next. Captures items from recent conversation (with confirmation) or from the argument, plus a clear intent line so no item gets discussed in a vacuum.
argument-hint: "<what this walk is about>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
---

<objective>
Capture a list of items (recommendations, todos, review comments) as a durable artifact you can walk through one at a time. Non-blocking discussion/fix/amend is the core loop; this command opens the walk, captures the purpose, and surfaces the first item grounded in that purpose.
</objective>

<principles>
- **Intent before mechanics.** Every walk has a one-sentence intent line and (optionally) a short approach paragraph. Items are always surfaced with that context — never raw mechanics in a vacuum. If the source items are mechanical ("loosen 5/16 lugnuts"), the intent frames them ("we're changing a tire").
- **Living, not frozen.** A walk is expected to change mid-flight. Items get added, dropped, or reworded. The list captured at start is a snapshot, not a contract.
- **One at a time.** The walk only ever surfaces one item as "current." The rest are visible in the file but not in your face.
- **Explicit items.** If no recent list exists in conversation, ask. Don't invent items.
- **Sanity-check decomposition.** Before accepting the item list, flag any items that appear to require functionality living in a later item (un-independently-verifiable steps). Offer to merge/re-sequence before the walk begins.
- **Cheap to start.** Opening a walk has the same cost profile as /rsd:handoff or /rsd:doc — no drama, no long prep.
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

7. **Capture the intent line (and optional approach).** Once items are confirmed, state what you understand the walk's purpose to be and ask the user to confirm or edit:

   > **Intent:** <your one-sentence reading of what this walk is trying to achieve>
   >
   > Does that capture it, or want to refine?

   If the items are highly mechanical or span multiple moving parts, also propose a short approach paragraph (one short paragraph on the high-level how) and ask the user to confirm:

   > **Approach:** <one short paragraph on the high-level approach>
   >
   > (optional — skip if the items speak for themselves)

   Store the confirmed intent and approach. The intent is required; the approach is optional.

8. **Verifiability sanity check.** Read the item list with this question in mind: *can each item be verified in isolation, or does any item depend on functionality that lives in a later item?*

   Common signals of a bad split:
   - Item N says "build feature X"; item N+1 says "add the test/validation/UI for X"
   - Item N creates a function; item N+1 is the first place that function is actually called
   - Items reference the same file/config key across the split

   For each affected item, prepare a flag: `item N: why flagged · raised at start`.

   If any flags, surface them *before* writing the walk file:

   > ⚠ Verifiability check: <item N> looks like it can't be tested without <item M>.
   > Options: merge N and M · re-sequence · proceed as-is (note stays in Flags)

   Wait for user direction. Apply their choice: merge → combine items and renumber; re-sequence → reorder items; proceed → keep items as-is but log the flag in the walk file's `## Flags` section.

9. **Write `.rsd/walks/${STAMP}-${SLUG}.md`** using the shape at `@${CLAUDE_PLUGIN_ROOT}/templates/WALK.md`. Fill in:
   - Header: title, timestamp, branch, commit, totals.
   - `## Intent` — the confirmed intent sentence.
   - `## Approach` — the confirmed approach paragraph (or a single `—` if the user opted to skip).
   - Each item: heading `### N. <short title> — unresolved`, verbatim recommendation text, empty Discussion, empty Resolution.
   - `## Flags` — any verifiability flags raised in step 8.

10. **Mark the walk active.**

    ```bash
    echo "${STAMP}-${SLUG}.md" > .rsd/walks/ACTIVE
    ```

11. **Commit and push** (single atomic commit):

    ```bash
    git add .rsd/walks/
    git commit -m "walk start: ${SLUG}" --no-verify
    git push 2>/dev/null || true
    ```

12. **Surface the first item, grounded in intent.** Brief format:

    ```
    Walk started: <N> items captured in `.rsd/walks/<file>`.

    **Intent:** <intent line>

    **Item 1 of N — <short title>**
    <recommendation text>
    <if flagged: ⚠ Verifiability flag: <why>>

    Discuss when ready. `/rsd:next <done|reject|defer|modify> [notes]` to advance.
    ```

    Keep it compact. Intent line always appears. No raw mechanics without the intent framing above them.

</process>

<guardrails>
- **Never surface an item without the intent line above it.** Mechanics without purpose is the anti-pattern this whole command exists to prevent.
- **Never fabricate items.** If the conversation has no list, ask. Don't guess.
- **Never fabricate intent.** If the walk's purpose is unclear from context, ask the user — don't invent a purpose.
- **Never silently overwrite an active walk.** If `.rsd/walks/ACTIVE` exists and points to a walk with unresolved items, stop and report.
- **Never skip the verifiability check on a list of 3+ items.** If the list is 1-2 items, skip. For 3+, run the check. Silent on no flags; explicit on any.
- **Never block on push failures.** Commit stands even if push fails; note it in the one-line report.
- **The argument is required.** Missing → ask and wait.
</guardrails>

<success>
- `.rsd/walks/YYYY-MM-DD-HHmm-<slug>.md` exists with items captured verbatim, plus Intent and (optionally) Approach sections.
- Any verifiability concerns surfaced, resolved with user input, and either fixed or flagged.
- `.rsd/walks/ACTIVE` points to the new walk file.
- Git commit created (`walk start: <slug>`).
- Push attempted.
- First item surfaced *grounded in the intent line*; session waits for discussion.
</success>
