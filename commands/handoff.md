---
name: rsd:handoff
description: Write a cold-start-ready handoff to .rsd/HANDOFF.md, commit, and push. Non-blocking — you can keep working after.
argument-hint: "[optional slug]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
---

<objective>
Write a handoff file that a fresh Claude session can read and resume from without asking questions. Non-blocking: call any time, keep working after, call again later with no cost.
</objective>

<principles>
- **Cheap to call.** No drama, no long summaries, no checking with the user mid-write. Calling /rsd:handoff five times in a session must cost nothing.
- **Verified outcomes only.** Things that actually ran, rendered, or passed go in "What just happened." Claims don't.
- **Cold-start readable.** A fresh Claude with no memory of this session must be able to pick up from the handoff alone.
- **Small.** Target under 100 lines. If it's long, you're writing documentation instead of a handoff.
- **Provisional.** Decisions logged here are not locked. Nothing in a handoff is a contract.
</principles>

<process>

1. **Walk up from cwd to find `.rsd/`.** If missing, create it:
   ```bash
   mkdir -p .rsd/handoffs
   ```

2. **Capture git context:**
   ```bash
   BRANCH=$(git branch --show-current 2>/dev/null || echo "(none)")
   COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "(none)")
   ```

3. **Capture context %:** Read from the statusline bridge file if present:
   ```bash
   CTX_FILE="${TMPDIR:-/tmp}/rsd-ctx-$CLAUDE_SESSION_ID.json"
   [ -f "$CTX_FILE" ] && USED=$(grep -o '"used_pct":[0-9]*' "$CTX_FILE" | cut -d: -f2)
   ```
   If unavailable, leave blank — don't block.

4. **Archive the previous handoff** (if `.rsd/HANDOFF.md` exists):
   ```bash
   STAMP=$(date +"%Y-%m-%d-%H%M")
   SLUG="${1:-$(date +%s)}"  # use arg if given, else epoch
   mv .rsd/HANDOFF.md ".rsd/handoffs/${STAMP}-${SLUG}.md"
   ```

5. **Check for active walk:**
   ```bash
   ACTIVE_WALK=""
   if [ -f .rsd/walks/ACTIVE ]; then
     ACTIVE_WALK=$(cat .rsd/walks/ACTIVE)
   fi
   ```

   If `$ACTIVE_WALK` is set, read `.rsd/walks/$ACTIVE_WALK` with the Read tool. Note:
   - Total items (`### ` headings under `## Items`)
   - Resolved count (headings whose status is not `— unresolved`)
   - Current item number + short title (first `— unresolved` heading)
   - Any entries in `## Flags` that reference the current item number

   If no active walk, skip to step 6.

6. **Synthesize the new handoff content** from the current session. Use the template at `@${CLAUDE_PLUGIN_ROOT}/templates/HANDOFF.md` as the shape. Fill in:

   - **What we're working on** — 1-3 sentences on the current focus. Honest about scope.
   - **What just happened** — 3-5 bullets of *verified* outcomes only. If you can't say what verified it, don't list it.
   - **What's open** — the specific unfinished thing, with reproduction steps or file refs, and the next likely action. Cold-start readable.

     **If an active walk exists** (from step 5), lead this section with the walk pointer on its own line:

     ```
     Active walk: .rsd/walks/<file> · <K> of <N> resolved · on item <M>: <title>
     Resume with /rsd:next.
     ```

     If you are mid-discussion on the current walk item (you were weighing options and have not yet resolved it), summarize the in-flight thinking in 1–3 sentences so a fresh Claude can pick up the *reasoning*, not just the pointer. If flags exist on the current item, mention them briefly.
   - **Recent decisions** — only decisions made *this session* worth remembering. Date, what, why.
   - **Open threads** — things noticed but deferred. Loose.

7. **Write `.rsd/HANDOFF.md`.** Use the Write tool.

8. **Commit and push** (single atomic commit). A handoff is a full save point, so sweep in everything — not just `.rsd/`. Whatever's in the working tree is state you might want when you resume:
   ```bash
   git add -A
   git commit -m "handoff: ${SLUG}" --no-verify
   ```

   **Handle reformatter residue.** Pre-commit and editor-triggered formatters (prettier, black, etc.) often rewrite files during or just after `git add` / `git commit` without re-staging. `--no-verify` doesn't always stop this — the file system layer runs the reformatter anyway. After the commit, check the tree and fold any residue into the same commit via amend:
   ```bash
   if [ -n "$(git status --porcelain)" ]; then
     git add -A
     git commit --amend --no-edit --no-verify
   fi
   ```
   Now verify truly clean:
   ```bash
   git status --porcelain
   ```
   This should output nothing. If it still prints anything, something unusual is happening (race with a background process, permission issue, nested repo) — surface it in the one-line report (step 9) rather than silently moving on.

   Finally push:
   ```bash
   git push 2>/dev/null || true  # push best-effort; don't fail if no remote
   ```

9. **Report briefly** — one line. If only `.rsd/` was touched: `Handoff written (43 lines, committed ${COMMIT}). Keep working or /clear → /rsd:pickup.` If the commit also swept in N other files: `Handoff written (43 lines) + 4 other files swept into commit ${COMMIT}. Working tree clean. Keep working or /clear → /rsd:pickup.` If the post-commit `git status --porcelain` is non-empty, flag it: `Handoff committed ${COMMIT}, but working tree not fully clean — <paths>. Investigate before /clear.`

</process>

<guardrails>
- **Never fabricate verification.** If a task wasn't actually verified, say so in "What's open" not "What just happened."
- **Never ask the user questions.** The handoff is write-only. If information is missing, mark it as unknown in the handoff and move on.
- **Never block on push failures.** If `git push` fails (no remote, auth, network), commit still stands; note it in the one-line report.
- **Don't re-explain context to the user.** They already know what happened — this file is for future-Claude, not for them.
</guardrails>

<success>
- `.rsd/HANDOFF.md` exists with the agreed sections filled in (or explicit "none" markers).
- Prior handoff archived to `.rsd/handoffs/YYYY-MM-DD-HHmm-<slug>.md`.
- Git commit created with message `handoff: <slug>`, sweeping in all staged/unstaged/untracked changes.
- Working tree is clean after the commit (nothing reported by `git status`).
- Push attempted (best-effort).
- One-line report to user. No further interaction required.
</success>
