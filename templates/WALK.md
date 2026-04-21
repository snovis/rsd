# Walk: {{title}}

Started: {{timestamp}} · Branch: {{branch}} · Start commit: {{commit_sha}}
Status: in progress
Totals: {{total}} items · {{done}} done · {{rejected}} rejected · {{deferred}} deferred · {{modified}} modified · {{unresolved}} unresolved

<!--
A walk is a living tasklist. Items are resolved one at a time via /rsd:next.
After each resolution, remaining items may be flagged for re-check if the fix
affected them. Flags are surfaced in chat and recorded inline, not auto-edited.
-->

## Items

### 1. {{item_title}} — unresolved

**Recommendation**
{{verbatim_item_text}}

**Discussion**
<!-- Free notes accumulate here across the walk. Empty until /rsd:next logs resolution. -->

**Resolution**
<!-- One of: done | reject | defer | modify · short reason / what was actually done. -->

### 2. {{item_title}} — unresolved

**Recommendation**
{{verbatim_item_text}}

**Discussion**

**Resolution**

<!-- …repeat for each item… -->

## Flags

<!--
Amend-pass notes surface here when a resolution on one item affects another.
Format: `item N: why flagged · raised after item M resolved`.
Never auto-rewrites items; just a heads-up for when we get there.
-->

## Summary

<!-- Written by /rsd:walk-done. Empty while the walk is in progress. -->
