---
name: rsd:doc
description: Save a substantial analysis or output from the current session to .rsd/docs/ as a durable markdown artifact. Requires an explicit title or description — never guesses.
argument-hint: "<what to save — short description>"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

<objective>
Preserve expensive analysis from the current session as a durable artifact before context is lost. Non-blocking: call any time, keep working after.

**What this is for:** long, substantive Claude output that took significant tokens to produce and would be painful to regenerate. Architecture analyses, debug walk-throughs, research summaries, migration plans.

**What this is NOT:** a handoff (that's /rsd:handoff — short, structured, future-Claude oriented). This is raw preservation of thinking.
</objective>

<principles>
- **Always explicit.** The argument IS the identifier. If no argument, stop and ask. Never guess.
- **Verbatim content.** Copy what Claude produced. Don't summarize, don't rewrite, don't "improve."
- **Thin wrapper.** Title, timestamp, context % — then the actual content.
- **Non-blocking.** Save, commit, report. Keep working.
</principles>

<process>

1. **Require an argument.** If the command was invoked with no argument, stop and ask:

   > Which analysis or output should I preserve? e.g. `/rsd:doc the code analysis`

   Wait for a user response. Do not proceed without an explicit description.

2. **Identify the content.** Based on the argument, locate the matching substantive output in recent conversation context. If there's any ambiguity (multiple candidates, or you're not sure what they meant), stop and ask the user to clarify before writing anything.

3. **Walk up from cwd to find `.rsd/`** (prefer sibling of `.git/`). Create `.rsd/docs/` if missing:

   ```bash
   mkdir -p .rsd/docs
   ```

4. **Capture metadata:**

   ```bash
   STAMP=$(date +"%Y-%m-%d-%H%M")
   BRANCH=$(git branch --show-current 2>/dev/null || echo "(none)")
   COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "(none)")
   CTX_FILE="${TMPDIR:-/tmp}/rsd-ctx-$CLAUDE_SESSION_ID.json"
   [ -f "$CTX_FILE" ] && USED=$(grep -o '"used_pct":[0-9]*' "$CTX_FILE" | cut -d: -f2)
   ```

5. **Generate slug** from the argument — lowercase, hyphens, strip punctuation. Keep under 40 chars.

6. **Write the file** to `.rsd/docs/${STAMP}-${SLUG}.md`:

   ```markdown
   # {{title_from_argument}}

   Written: {{timestamp}} · Context at save: {{pct}}%
   Branch: {{branch}} · Commit: {{commit}}

   ## Content

   {{verbatim content from conversation}}
   ```

   Use the Write tool. Content is verbatim — do not rephrase or summarize.

7. **Commit and push:**

   ```bash
   git add .rsd/docs/
   git commit -m "doc: ${SLUG}" --no-verify
   git push 2>/dev/null || true
   ```

8. **Report briefly** — one line:

   `Saved to .rsd/docs/{filename}.md ({N} lines, committed {commit}). Keep working or /rsd:ho to handoff.`

</process>

<guardrails>
- **Never save without an argument.** Missing arg → ask and wait.
- **Never summarize or rewrite content.** Copy verbatim from the conversation.
- **Never decide what to save on the user's behalf.** If ambiguous, ask which content they meant.
- **Never block on push failures.** Commit stands even if push fails; note it in the report.
</guardrails>

<success>
- `.rsd/docs/YYYY-MM-DD-HHmm-<slug>.md` exists with verbatim content.
- Git commit created (`doc: <slug>`).
- Push attempted.
- One-line report to user. No further questions asked.
</success>
