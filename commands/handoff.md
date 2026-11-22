---
name: rsd:handoff
description: Write a cold-start-ready handoff to .rsd/HANDOFF.md (plus durable facts in .rsd/FACTS.md), commit, and push. Non-blocking — you can keep working after.
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
- **Reasons, not just conclusions.** A conclusion without its reason invites the next agent to fill the gap with an assumption. Every decision says why, and what was rejected and why. Every fact says how we know it.
- **Nothing silently decays.** `HANDOFF.md` is replaced each time, so anything that must survive more than one session lives in `.rsd/FACTS.md` (edited in place, never archived) or is carried forward explicitly. "Not mentioned this session" is never a reason to drop something.
- **Small where it can be.** `HANDOFF.md` targets under 100 lines — trim prose, never reasons. `.rsd/FACTS.md` has no line cap, but each entry stays one or two lines.
- **Provisional.** Decisions logged here are not locked. Nothing in a handoff is a contract — but a decision stays in force until a newer one replaces it.
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
   - **behind > 0, ahead > 0** — histories diverged. Remember **integrate-after-commit** and proceed. Local work gets committed first (step 10) so nothing can be lost, then integrated.

4. **Capture context %.** Note the current context-used percentage if it's known (e.g. from the statusline). If unavailable, leave it blank — don't block.

5. **Read, then archive the previous handoff** (only if `<root>/.rsd/HANDOFF.md` exists). First Read it with the Read tool and keep its **Decisions in force** (older handoffs may call it **Recent decisions**) and **Open threads** in mind — step 8 carries them forward. Then get a timestamp with one command:
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

7. **Update the durable facts file, `<root>/.rsd/FACTS.md`.** This file is never archived or overwritten — edit it in place with the Edit tool. If it doesn't exist, create it with the Write tool using `@${CLAUDE_PLUGIN_ROOT}/templates/FACTS.md` as the shape, and seed it from anything durable in the previous handoff (step 5) and this session.

   Ask yourself: *what did this session learn that a fresh Claude would otherwise rediscover, guess at, or rebuild?* Record it in the right section:

   - **Ground truth** — how things work here: where secrets and keys live and how to read them, how to deploy, which machine or service does what, what access the agent already has. Tag each entry `[verified]` (say how), `[inferred]`, or `[unknown]`.
   - **Solved — don't redo** — problem → solution → where it lives. Anything that took real effort to figure out belongs here.
   - **Dead ends** — approaches tried and rejected, with why. Include sophisticated ones; those cost the most to rediscover.

   Upgrade `[inferred]` to `[verified]` when this session checked it. Never delete an entry: if this session contradicted one, move it to **Retired** with the date and what contradicted it. Never write a secret value — only where it lives and how to read it. If nothing new was learned, leave the file untouched (just note `facts: no change` for the report).

8. **Synthesize the new handoff content** from the current session. Use the template at `@${CLAUDE_PLUGIN_ROOT}/templates/HANDOFF.md` as the shape. Fill in:

   - **Durable facts header line** — the counts from `.rsd/FACTS.md` (ground-truth entries, solved, dead ends).
   - **What we're working on** — 1-3 sentences on the current focus. Honest about scope. Plus a **Why:** line — the goal this serves, so the next agent can judge what's on-path.
   - **What just happened** — 3-5 bullets of *verified* outcomes only, each with what verified it. If you can't say what verified it, don't list it.
   - **What's open** — the specific unfinished thing, with reproduction steps or file refs, the next likely action, **why** that's next, and what is explicitly **out of scope** for that step. Cold-start readable.

     **If an active walk exists** (from step 6), lead this section with the walk pointer on its own line:

     ```
     Active walk: .rsd/walks/<file> · <K> of <N> resolved · on item <M>: <title>
     Resume with /rsd:next.
     ```

     If you are mid-discussion on the current walk item (you were weighing options and have not yet resolved it), summarize the in-flight thinking in 1–3 sentences so a fresh Claude can pick up the *reasoning*, not just the pointer. If flags exist on the current item, mention them briefly.
   - **Decisions in force** — every decision from the previous handoff that still holds, plus this session's. Format: `date · chose X · because Y · rejected Z because W`. Drop an old one only when a newer decision replaces it, and say so in the new one. If an old entry has no reason recorded, keep it and mark the reason `(not recorded)` — don't invent one. If a decision is really a durable fact (e.g. "keys come from the vault"), put it in `.rsd/FACTS.md` instead.
   - **Open threads** — carried forward from the previous handoff plus new ones. Drop a thread only if it was resolved (and say where, in "What just happened") or moved into the current focus.

9. **Write `<root>/.rsd/HANDOFF.md`.** Use the Write tool.

10. **Commit and push** (single atomic commit). A handoff is a full save point, so sweep in everything — not just `.rsd/`. Whatever's in the working tree is state you might want when you resume. Stage, then commit (each its own command; substitute the literal slug):
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
   This should output nothing. If it still prints anything, something unusual is happening (race with a background process, permission issue, nested repo) — surface it in the one-line report (step 11) rather than silently moving on.

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
     Skip the push. The local commit stands; report the divergence loudly in step 11.

   Finally push (best-effort — if it fails, e.g. no remote, the commit still stands; note it in the report):
   ```bash
   git push
   ```
   If the push is rejected as non-fast-forward, do NOT use `--force` or `--force-with-lease` — report it instead.

11. **Report briefly** — one line. If only `.rsd/` was touched: `Handoff written (43 lines, facts +2, committed ${COMMIT}). Keep working or /clear → /rsd:pickup.` If the commit also swept in N other files: `Handoff written (43 lines, facts +2) + 4 other files swept into commit ${COMMIT}. Working tree clean. Keep working or /clear → /rsd:pickup.` Use `facts +N` for entries added/changed in `.rsd/FACTS.md`, `facts: no change` if none, or `facts: created` the first time. If remote commits were pulled or integrated, append it: `…(pulled 2 remote commits first)`. If the post-commit `git status --porcelain` is non-empty, flag it: `Handoff committed ${COMMIT}, but working tree not fully clean — <paths>. Investigate before /clear.` If integration was aborted on conflicts, make that the headline: `Handoff committed ${COMMIT} locally, but NOT pushed — remote has diverged with conflicts in <paths>. Reconcile (git pull --rebase, resolve, git push) before switching machines.`

</process>

<guardrails>
- **Never fabricate verification.** If a task wasn't actually verified, say so in "What's open" not "What just happened."
- **Never ask the user questions.** The handoff is write-only. If information is missing, mark it as unknown in the handoff and move on.
- **Never record a conclusion without its reason.** If the reason is lost, write `(not recorded)` — a visible gap is better than one the next agent fills with a guess.
- **Never write secret values** into `HANDOFF.md` or `FACTS.md`. Record where a secret lives and how to read it.
- **Never shrink FACTS.md to save lines.** Retire contradicted entries; don't delete them.
- **Never block on push failures.** If `git push` fails (no remote, auth, network), commit still stands; note it in the one-line report.
- **Never clobber the remote.** Fetch and compare before writing; integrate remote commits before pushing. Never force-push, never resolve non-handoff conflicts by guessing — abort, keep the local commit, and tell the user.
- **Don't re-explain context to the user.** They already know what happened — this file is for future-Claude, not for them.
</guardrails>

<success>
- `.rsd/HANDOFF.md` exists with the agreed sections filled in (or explicit "none" markers).
- Prior handoff read, then archived to `.rsd/handoffs/YYYY-MM-DD-HHmm-<slug>.md`; its still-valid decisions and open threads carried forward.
- `.rsd/FACTS.md` exists and holds everything durable this session learned (ground truth, solved, dead ends), each with a status and a reason.
- Every decision in the handoff has a reason and, where one existed, the rejected alternative.
- Remote checked (`git fetch` + behind/ahead) before anything was written; remote-only commits pulled or integrated, or the divergence reported. No force pushes.
- Git commit created with message `handoff: <slug>`, sweeping in all staged/unstaged/untracked changes.
- Working tree is clean after the commit (nothing reported by `git status`).
- Push attempted (best-effort).
- One-line report to user. No further interaction required.
</success>
