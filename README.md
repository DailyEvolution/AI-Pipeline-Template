# Pipeline template

The files from the *Return Edge* runbook, as a repository rather than a
document. Every workflow, script, ruleset and skill the runbook shows is
here at the path the runbook names, and the parts that can run without
GitHub have run.

This is a governance layer, not an application. The three-file app in
`src/` and `tests/` exists so the gates have something real to evaluate.
Replace it with yours.

## What has actually been exercised

`npm run selftest` runs everything that does not need a GitHub
repository. On the commit you are reading, it passes. What it proves:

| Component | How it was exercised |
|---|---|
| `scripts/gates/tests-executed.sh` | Against a real Vitest JSON report; then against a report that ran nothing (fails as designed) |
| `scripts/gates/tests-changed-with-src.sh` | Against four real commits on a throwaway git history: src+tests, src only (fails), tests only, neither |
| `scripts/gates/scan-provenance.sh` | Report newer than the marker (passes); older (fails); tracked by git (fails) |
| `scripts/tier-from-paths.sh` | Eight scenarios on real diffs: copy-only stays T0; T2 never lowers; no issue defaults T3; `migrations/`, `src/auth/`, `openapi.yaml`, `tests/`, `.github/` each raise to the documented floor |
| `scripts/parse-issue-form.sh` | Sponsor and requester extracted from an issue-form body; missing field yields empty; shell metacharacters in the body come back as text and are not executed |
| `receiver/receiver.js` | Four `node --test` cases: constant-time signature verify, 401 without calling GitHub, dispatch payload contains exactly the five allowed fields, title bounded at 200 chars |
| `scripts/gates/log.sh` | Two evaluations appended as valid NDJSON; a pass is recorded, not only a failure |
| Every workflow | Parses as YAML **and** parses under `act` with Actions semantics |
| `rulesets/*.json` | Valid JSON; the checks ruleset has no bypass actors; the review ruleset has exactly one, an `Integration` with `bypass_mode: always`, and requires last-push approval |
| Cross-checks | Every required status check names a job that exists in `gates.yml`; `t0-merge.yml` listens for the Gates workflow by its exact name; every path rule in the script appears in `docs/tiers.md` |

## What has not been exercised, and cannot be here

- **No workflow has executed.** `act` parsed them; it did not run them.
  Running them needs a GitHub repository, the two apps installed, and
  the secrets in place.
- **No `gh` call has been made.** Every `gh` invocation in the workflows
  and in `scripts/bootstrap-repo.sh` is syntax-checked only.
- **No ruleset has been applied.** The JSON is the documented shape.
  Whether `actor_id` for an `Integration` is the App ID (as this repo
  assumes) is confirmed by the first `gh api` call, not by anything here.
- **The GitHub MCP tool names** in `heal-oldest-t0`, `corpus-update`,
  `classify-tier` and `triage.yml` are unverified against the action's
  bundled server. A wrong name is a silent no-op.
- **The `claude-code-action` runs** — classify, heal, triage, learn — need
  `ANTHROPIC_API_KEY` and a real issue to act on.

## Order of operations on a real repository

1. Put your application in place of `src/` and `tests/`; keep the gate
   scripts and `package.json` scripts.
2. `/install-github-app` from Claude Code. Create the pipeline app
   (permissions in `scripts/bootstrap-repo.sh` header comments). Store
   `PIPELINE_APP_ID`, `PIPELINE_APP_PRIVATE_KEY`, `ONCALL_SPONSOR`.
3. `PIPELINE_APP_ID=<id> scripts/bootstrap-repo.sh <org> <repo>`.
4. Open a pull request by hand. Confirm `Gates / classify` and
   `Gates / verify` report, and that the PR cannot merge without them.
5. Only then let `heal.yml` run on its schedule. Only after a T0 heal PR
   has merged by hand once, and the ruleset log shows what you expect,
   enable `t0-merge.yml`.

The runbook's phase order applies. Nothing in Phase 4 is safe until
Phase 2's gates have failed on purpose in front of you at least once.
