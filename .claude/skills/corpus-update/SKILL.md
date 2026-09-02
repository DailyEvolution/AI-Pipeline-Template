---
name: corpus-update
description: After an incident closes, propose the corpus change that would have caught it.
argument-hint: [issue-number]
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Bash(npm test *)
  - Bash(git checkout -b *)
  - Bash(git add *)
  - Bash(git commit *)
  - Bash(git push -u origin *)
  - mcp__github__issue_read
  - mcp__github__pull_request_read
  - mcp__github__create_pull_request
---

Read incident issue $ARGUMENTS and the pull request that resolved it.

Answer one question: which gate should have caught this, and why
didn't it? Then open a PR containing at most three of:

- A regression test at the layer the defect crossed.
- A `CLAUDE.md` line, but only if the defect came from a convention an
  agent could not have known. Not a restatement of the fix.
- A change to an existing gate, with the specific assertion that would
  have failed.
- A `.claude/skills/*` step, if the procedure was followed correctly
  and was still wrong.

If none of these apply — the defect was a genuine one-off — say so in
the PR description and propose nothing. An honest "no change" is a
valid outcome; a plausible-looking rule is not.

Never weaken an existing assertion. Never mark a test as skipped.
