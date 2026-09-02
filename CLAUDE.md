# Conventions

Every line here changes what gets written. If a line only describes the
project, delete it — Claude can read the project.

## Copy
User-facing strings live in `src/copy/strings.js` and nowhere else. A
string literal in `src/` outside that file fails review.

## Errors
Throw `Error` with a message that names the missing thing (`name is
required`), never a bare `throw new Error()`. Callers match on message.

## Tests
Every bug fix adds a test that fails on the commit before it. If you
cannot write that test, say so in the PR description rather than adding
a test that passes either way. Never change an existing assertion to
make a change pass; if an assertion is wrong, say so and stop.

## Things that look wrong and are not
- `tests/contract/` is empty on purpose. It is where `/add-endpoint`
  puts contract tests. Do not delete the directory.

## Pull requests you open
- The body contains `Closes #<issue>` on its own line. The gates read
  that link to find the issue's tier. No link, no tier, no merge.
- Never a draft. A draft cannot be merged by the T0 workflow.
