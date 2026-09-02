---
name: classify-tier
description: Assign a provisional reversibility tier to an issue from its text and the tier table in docs/tiers.md.
argument-hint: [issue-number]
allowed-tools: Read Grep Glob mcp__github__issue_read mcp__github__issue_write
---

Read issue $ARGUMENTS and `docs/tiers.md`. Decide which tier the change
would fall in if implemented as described.

Replace `tier:unclassified` with exactly one of `tier:T0`, `tier:T1`,
`tier:T2`, `tier:T3`, and comment with one sentence of reasoning.

If the issue does not say enough to decide — no surface named, no
behaviour described, a request you would need to ask about — label it
`tier:T3` and say why. Do not guess downward.
