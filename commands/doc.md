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

3. **Locate the project root.** Run one command:

   ```bash
   git rev-parse --show-toplevel
   ```

   Use the returned path as an absolute prefix (`<root>/.rsd/...`) below; if it errors (not a git repo), use the current working directory. Create the docs dir if missing:

   ```bash
   mkdir -p <root>/.rsd/docs
   ```

4. **Capture metadata.** Run each as its own command and note the output (treat empty output or an error as `(none)`):

   ```bash
   date +"%Y-%m-%d-%H%M"
   ```
   ```bash
   git branch --show-current
   ```
   ```bash
   git rev-parse --short HEAD
   ```

   Note the current context-used percentage if it's known (e.g. from the statusline); otherwise leave it blank.

5. **Generate slug** from the argument — lowercase, hyphens, strip punctuation. Keep under 40 chars.

6. **Write the file** (Write tool) to `<root>/.rsd/docs/<stamp>-<slug>.md`, substituting the literal stamp and slug:

   ```markdown
   # {{title_from_argument}}

   Written: {{timestamp}} · Context at save: {{pct}}%
   Branch: {{branch}} · Commit: {{commit}}

   ## Content

   {{verbatim content from conversation}}
   ```

   Use the Write tool. Content is verbatim — do not rephrase or summarize.

7. **Commit and push** (each its own command; substitute the literal slug; push is best-effort):

   ```bash
   git add <root>/.rsd/docs/
   ```
   ```bash
   git commit -m "doc: <slug>" --no-verify
   ```
   ```bash
   git push
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
