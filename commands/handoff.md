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

5. **Synthesize the new handoff content** from the current session. Use the template at `@$HOME/.claude/plugins/rsd/templates/HANDOFF.md` as the shape. Fill in:

   - **What we're working on** — 1-3 sentences on the current focus. Honest about scope.
   - **What just happened** — 3-5 bullets of *verified* outcomes only. If you can't say what verified it, don't list it.
   - **What's open** — the specific unfinished thing, with reproduction steps or file refs, and the next likely action. Cold-start readable.
   - **Recent decisions** — only decisions made *this session* worth remembering. Date, what, why.
   - **Open threads** — things noticed but deferred. Loose.

6. **Write `.rsd/HANDOFF.md`.** Use the Write tool.

7. **Commit and push** (single atomic commit):
   ```bash
   git add .rsd/
   git commit -m "handoff: ${SLUG}" --no-verify
   git push 2>/dev/null || true  # push best-effort; don't fail if no remote
   ```

8. **Report briefly** — one line. Example: `Handoff written (43 lines, committed ${COMMIT}). Keep working or /clear → /rsd:pickup.`

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
- Git commit created with message `handoff: <slug>`.
- Push attempted (best-effort).
- One-line report to user. No further interaction required.
</success>
