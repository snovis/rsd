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

1. **Locate the project root.** Run one command:
   ```bash
   git rev-parse --show-toplevel
   ```
   Use the returned path as an absolute prefix (`<root>/.rsd/...`) for every file operation below. If the command errors (not a git repo), use the current working directory as the root. Ensure the handoffs dir exists:
   ```bash
   mkdir -p <root>/.rsd/handoffs
   ```

2. **Capture git context.** Run each as its own command and note the output (treat empty output or an error as `(none)`):
   ```bash
   git branch --show-current
   ```
   ```bash
   git rev-parse --short HEAD
   ```

3. **Sync with the remote before writing anything.** Another machine may have pushed a newer handoff — never clobber it. Run:
   ```bash
   git fetch
   ```
   If the fetch fails (no remote, offline, auth), note `sync skipped: <reason>` for the report and continue — never block. Otherwise compare against upstream:
   ```bash
   git rev-list --left-right --count @{upstream}...HEAD
   ```
   If this errors (no upstream configured for the branch), note it and continue. Otherwise the output is `<behind>	<ahead>`:

   - **behind = 0** — local already has everything the remote has. Proceed.
   - **behind > 0, ahead = 0** — the remote is strictly newer (classic forgot-to-pull-on-this-machine). Fast-forward now, before archiving or writing anything:
     ```bash
     git pull --ff-only
     ```
     If it succeeds, note `pulled <behind> remote commits` for the report and proceed — the freshly pulled `HANDOFF.md` is the one step 5 will archive. If it fails (uncommitted local changes overlap the incoming ones), do NOT escalate to anything stronger; remember the flag **integrate-after-commit** and proceed.
   - **behind > 0, ahead > 0** — histories diverged. Remember **integrate-after-commit** and proceed. Local work gets committed first (step 9) so nothing can be lost, then integrated.

4. **Capture context %.** Note the current context-used percentage if it's known (e.g. from the statusline). If unavailable, leave it blank — don't block.

5. **Archive the previous handoff** (only if `<root>/.rsd/HANDOFF.md` exists). Get a timestamp with one command:
   ```bash
   date +"%Y-%m-%d-%H%M"
   ```
   Use the command argument as the slug if given; otherwise get an epoch fallback:
   ```bash
   date +%s
   ```
   Then move the old handoff aside, substituting the literal stamp and slug:
   ```bash
   mv <root>/.rsd/HANDOFF.md <root>/.rsd/handoffs/<stamp>-<slug>.md
   ```

6. **Check for active walk.** Use the Read tool on `<root>/.rsd/walks/ACTIVE`. If that file exists, its contents name the active walk file — Read `<root>/.rsd/walks/<name>` with the Read tool. Note:
   - Total items (`### ` headings under `## Items`)
   - Resolved count (headings whose status is not `— unresolved`)
   - Current item number + short title (first `— unresolved` heading)
   - Any entries in `## Flags` that reference the current item number

   If no active walk, skip to step 7.

7. **Synthesize the new handoff content** from the current session. Use the template at `@${CLAUDE_PLUGIN_ROOT}/templates/HANDOFF.md` as the shape. Fill in:

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

8. **Write `<root>/.rsd/HANDOFF.md`.** Use the Write tool.

9. **Commit and push** (single atomic commit). A handoff is a full save point, so sweep in everything — not just `.rsd/`. Whatever's in the working tree is state you might want when you resume. Stage, then commit (each its own command; substitute the literal slug):
   ```bash
   git add -A
   ```
   ```bash
   git commit -m "handoff: <slug>" --no-verify
   ```

   **Handle reformatter residue.** Pre-commit and editor-triggered formatters (prettier, black, etc.) often rewrite files during or just after `git add` / `git commit` without re-staging. `--no-verify` doesn't always stop this. After the commit, check the tree:
   ```bash
   git status --porcelain
   ```
   If that prints anything, fold the residue into the same commit — stage, then amend (two separate commands):
   ```bash
   git add -A
   ```
   ```bash
   git commit --amend --no-edit --no-verify
   ```
   Then check once more:
   ```bash
   git status --porcelain
   ```
   This should output nothing. If it still prints anything, something unusual is happening (race with a background process, permission issue, nested repo) — surface it in the one-line report (step 10) rather than silently moving on.

   **Integrate deferred remote commits.** If step 3 set **integrate-after-commit**, local work is now safely committed — bring in the remote side:
   ```bash
   git pull --rebase
   ```
   If it completes cleanly, note `integrated <behind> remote commits` and proceed to push. If it stops on conflicts, list them:
   ```bash
   git diff --name-only --diff-filter=U
   ```
   - **Only `.rsd/HANDOFF.md` conflicts** (the expected case when two machines both handed off): preserve the remote version first. Run `git show HEAD:.rsd/HANDOFF.md` (during a rebase, `HEAD` is the remote side) and use the Write tool to save its output to `<root>/.rsd/handoffs/<stamp>-<slug>-remote.md`. Then keep the handoff you just wrote and continue (each its own command):
     ```bash
     git checkout --theirs -- .rsd/HANDOFF.md
     ```
     ```bash
     git add -A
     ```
     ```bash
     git rebase --continue
     ```
   - **Any other path conflicts:** never guess at merge resolutions inside a handoff. Abort:
     ```bash
     git rebase --abort
     ```
     Skip the push. The local commit stands; report the divergence loudly in step 10.

   Finally push (best-effort — if it fails, e.g. no remote, the commit still stands; note it in the report):
   ```bash
   git push
   ```
   If the push is rejected as non-fast-forward, do NOT use `--force` or `--force-with-lease` — report it instead.

10. **Report briefly** — one line. If only `.rsd/` was touched: `Handoff written (43 lines, committed ${COMMIT}). Keep working or /clear → /rsd:pickup.` If the commit also swept in N other files: `Handoff written (43 lines) + 4 other files swept into commit ${COMMIT}. Working tree clean. Keep working or /clear → /rsd:pickup.` If remote commits were pulled or integrated, append it: `…(pulled 2 remote commits first)`. If the post-commit `git status --porcelain` is non-empty, flag it: `Handoff committed ${COMMIT}, but working tree not fully clean — <paths>. Investigate before /clear.` If integration was aborted on conflicts, make that the headline: `Handoff committed ${COMMIT} locally, but NOT pushed — remote has diverged with conflicts in <paths>. Reconcile (git pull --rebase, resolve, git push) before switching machines.`

</process>

<guardrails>
- **Never fabricate verification.** If a task wasn't actually verified, say so in "What's open" not "What just happened."
- **Never ask the user questions.** The handoff is write-only. If information is missing, mark it as unknown in the handoff and move on.
- **Never block on push failures.** If `git push` fails (no remote, auth, network), commit still stands; note it in the one-line report.
- **Never clobber the remote.** Fetch and compare before writing; integrate remote commits before pushing. Never force-push, never resolve non-handoff conflicts by guessing — abort, keep the local commit, and tell the user.
- **Don't re-explain context to the user.** They already know what happened — this file is for future-Claude, not for them.
</guardrails>

<success>
- `.rsd/HANDOFF.md` exists with the agreed sections filled in (or explicit "none" markers).
- Prior handoff archived to `.rsd/handoffs/YYYY-MM-DD-HHmm-<slug>.md`.
- Remote checked (`git fetch` + behind/ahead) before anything was written; remote-only commits pulled or integrated, or the divergence reported. No force pushes.
- Git commit created with message `handoff: <slug>`, sweeping in all staged/unstaged/untracked changes.
- Working tree is clean after the commit (nothing reported by `git status`).
- Push attempted (best-effort).
- One-line report to user. No further interaction required.
</success>
