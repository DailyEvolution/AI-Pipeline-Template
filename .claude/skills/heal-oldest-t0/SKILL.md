---
name: heal-oldest-t0
description: Pick up the oldest open tier-T0 heal ticket and propose a fix as a pull request.
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Bash(npm test *)
  - Bash(npm run test:* *)
  - Bash(git checkout -b *)
  - Bash(git add *)
  - Bash(git commit *)
  - Bash(git push -u origin *)
  - mcp__github__issue_read
  - mcp__github__issue_write
  - mcp__github__create_pull_request
---

Take the oldest open issue labelled `pipeline:heal` and `tier:T0` that
has no linked pull request.

1. Reproduce first. Write a failing test that demonstrates the error
   from the stack trace. If you cannot reproduce it, comment on the
   issue with what you tried and stop. Do not guess at a fix.
2. Fix the source. Do not change existing assertions.
3. Run the full suite locally before opening anything.
4. Open a pull request — not a draft; a draft cannot be merged by the
   T0 workflow. The body must contain `Closes #<issue>` on its own line:
   that link is how the gates find the provisional tier. State the
   reproduction, the fix, and what you could not verify.
5. If the fix requires touching anything outside `src/`, stop and
   escalate on the issue instead. That is no longer T0.
