# Handoff

Written: {{timestamp}} · Context used: {{context_pct}}%
Branch: {{branch}} · Last commit: {{commit_sha}}
Durable facts: .rsd/FACTS.md ({{facts_count}} ground-truth entries, {{solved_count}} solved, {{dead_end_count}} dead ends) — read it before building anything not listed under "Next likely action".

## What we're working on

{{focus_sentences}}

Why: {{why_this_matters}}

Slice: {{slice_line}}
<!-- Area and Intent lines appear here when those levels exist -->

## What just happened

<!-- 3-5 bullets of verified outcomes. Things that ran, rendered, or passed — not claims. Say what verified it. -->
- {{outcome_1}} — verified by: {{evidence_1}}
- {{outcome_2}} — verified by: {{evidence_2}}
- {{outcome_3}} — verified by: {{evidence_3}}

## What's open

<!-- The specific unfinished thing at the top of the stack. Cold-start readable. -->
- Open: {{open_thing}}
- Reproduce/check by: {{repro_steps}}
- Next likely action: {{next_action}}
- Why that's next: {{why_next}}
- Out of scope for the next step: {{not_now}}

## Decisions in force

<!--
Provisional, not locked — but carried forward from the previous handoff until superseded.
Drop a decision only when a newer one replaces it (say so in the new one).
Format: date · chose X · because Y · rejected Z because W.
-->
- {{date}} · chose {{decision}} · because {{reason}} · rejected {{alternative}} because {{why_not}}

## Open threads (not current focus)

<!-- Loose list. Things noticed but deferred. Free-form. -->
- {{thread}}
