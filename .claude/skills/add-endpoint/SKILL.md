---
name: add-endpoint
description: Add an HTTP endpoint with its handler, contract test and OpenAPI entry. Use whenever a new API route is being added.
allowed-tools: Read Grep Glob Edit Write
---

1. Handler in `src/api/<resource>.js`. Validate input at the boundary;
   do not hand-roll validation deeper in.
2. Contract test in `tests/contract/<resource>.test.js` covering the
   happy path, one validation failure, and one authorization failure.
3. Add the path to `openapi.yaml`. Touching that file raises the change
   to T2; say so in the PR body.
4. Run `npm run test:contract` before proposing the change.
