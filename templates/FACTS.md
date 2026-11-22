# Project facts

<!--
Durable. This file is NEVER archived or overwritten by a handoff — it is edited in place.
It holds what a fresh Claude would otherwise rediscover, guess at, or rebuild.

Rules:
- Every entry carries a status: [verified] (ran it / saw it, say how), [inferred] (reasoned, not checked), [unknown] (open question).
- Add the *why* and *how we know*, not just the conclusion. One or two lines per entry.
- Never delete an entry silently. If something is contradicted, move it to "Retired" with the date and what contradicted it.
- No secret VALUES here. Say where a secret lives and how to read it, never the secret itself.
-->

Last updated: {{timestamp}}

## Ground truth

<!-- How things work here: where secrets/keys live and how to read them, how to deploy, which machine/service does what, access the agent already has. -->
- [{{status}}] {{fact}} — how we know: {{evidence}} ({{date}})

## Solved — don't redo

<!-- Problems that are already solved. Format: problem → solution → where it lives. If you're about to build tooling for one of these, stop. -->
- {{problem}} → {{solution}} → {{location}} ({{date}})

## Dead ends — tried, didn't work

<!-- Approaches already tried and rejected. Format: what we tried → why it failed / why we rejected it. Saves the next agent from walking the same alley. -->
- {{approach}} → {{why_rejected}} ({{date}})

## Retired

<!-- Facts that turned out to be wrong or stale. Format: old fact → what contradicted it (date). -->
- (none)
