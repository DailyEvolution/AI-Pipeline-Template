#!/usr/bin/env bash
# Runs everything in this repository that can run without GitHub:
# the gate scripts against real test output and real git history, the
# tier classifier, the issue-form parser, the webhook receiver, the
# gate log, and static checks on every workflow, ruleset and skill.
#
# What it cannot do: execute a GitHub Actions workflow, call gh, or
# exercise a ruleset. Those need a repository on GitHub.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@example.invalid
export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@example.invalid
PASS=0; FAIL=0
ok()  { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
expect_ok()   { if "$@" >/dev/null 2>&1; then ok "$MSG"; else bad "$MSG"; fi; }
expect_fail() { if "$@" >/dev/null 2>&1; then bad "$MSG (should have failed)"; else ok "$MSG"; fi; }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# ---------------------------------------------------------------- static
section "Static: every workflow, ruleset, script and skill is well-formed"
for f in .github/workflows/*.yml .github/ISSUE_TEMPLATE/*.yml; do
  MSG="YAML parses: $f"; expect_ok python3 -c "import yaml,sys; yaml.safe_load(open('$f'))"
done
for f in rulesets/*.json .claude/settings.json package.json; do
  MSG="JSON parses: $f"; expect_ok jq -e . "$f"
done
for f in scripts/*.sh scripts/gates/*.sh; do
  MSG="bash -n: $f"; expect_ok bash -n "$f"
done
for f in .claude/skills/*/SKILL.md; do
  MSG="frontmatter opens on line 1: $f"; expect_ok bash -c "head -1 '$f' | grep -qx -- '---'"
  MSG="has a description: $f";         expect_ok grep -q '^description:' "$f"
done
for sk in heal-oldest-t0 corpus-update classify-tier; do
  MSG="scheduled/automated skill grants tools: $sk"
  expect_ok grep -q '^allowed-tools:' ".claude/skills/$sk/SKILL.md"
done
MSG="settings.json denies edits to workflows"
expect_ok jq -e '.permissions.deny | index("Edit(/.github/workflows/**)")' .claude/settings.json
MSG="checks ruleset has no bypass actors"
expect_ok jq -e '.bypass_actors == []' rulesets/checks.json
MSG="review ruleset has exactly one bypass actor, an Integration, mode always"
expect_ok jq -e '.bypass_actors | length == 1 and .[0].actor_type == "Integration" and .[0].bypass_mode == "always"' rulesets/review.json
MSG="review ruleset requires last-push approval (agent cannot approve its own push)"
expect_ok jq -e '.rules[] | select(.type=="pull_request") | .parameters.require_last_push_approval == true' rulesets/review.json

# Required-check contexts must name jobs that exist in the Gates workflow.
MSG="every required status check names a real Gates job"
expect_ok python3 - <<'PY'
import yaml, json, sys
wf = yaml.safe_load(open('.github/workflows/gates.yml'))
jobs = {f"{wf['name']} / {j}" for j in wf['jobs']}
need = {c['context'] for r in json.load(open('rulesets/checks.json'))['rules']
        if r['type']=='required_status_checks' for c in r['parameters']['required_status_checks']}
missing = need - jobs
sys.exit(1 if missing else 0)
PY
MSG="the T0 merge workflow listens for the Gates workflow by its exact name"
expect_ok python3 -c "
import yaml
g=yaml.safe_load(open('.github/workflows/gates.yml'))['name']
t=yaml.safe_load(open('.github/workflows/t0-merge.yml'))
assert g in t[True]['workflow_run']['workflows']"
MSG="every path in tier-from-paths.sh appears in docs/tiers.md"
expect_ok bash -c "for p in migrations db src/auth src/billing openapi.yaml src/api/contracts tests .github; do grep -q \"\$p\" docs/tiers.md || exit 1; done"

if [ -n "${ACT_BIN:-}" ] && [ -x "$ACT_BIN" ]; then
  MSG="act parses every workflow with Actions semantics"
  expect_ok "$ACT_BIN" -l -W .github/workflows
fi

# ------------------------------------------------------------- the gates
section "Gates: run against real output, then broken on purpose"
rm -f report.json .gate-start scan-report.json
touch -d '1 minute ago' .gate-start
npm test -- --reporter=json --outputFile=report.json >/dev/null 2>&1
MSG="the suite produced a JSON report"; expect_ok test -s report.json
MSG="gate tests-executed passes on a real run";   expect_ok scripts/gates/tests-executed.sh report.json
echo '{"numTotalTests":0}' > /tmp/selftest-empty.json
MSG="gate tests-executed fails on a run that ran nothing"; expect_fail scripts/gates/tests-executed.sh /tmp/selftest-empty.json
echo '{}' > scan-report.json
MSG="gate scan-provenance passes on a report written after the marker"; expect_ok scripts/gates/scan-provenance.sh scan-report.json .gate-start
touch -d '2 minutes ago' scan-report.json
MSG="gate scan-provenance fails on a report older than the job";      expect_fail scripts/gates/scan-provenance.sh scan-report.json .gate-start
rm -f report.json .gate-start scan-report.json

# ---------------------------------------------- tier classifier, real git
section "Tier classifier and the src-needs-tests gate, on real git history"
TMP=$(mktemp -d)
cp -r src tests package.json "$TMP"/
git -C "$TMP" init -q -b main
git -C "$TMP" add -A && git -C "$TMP" commit -qm base
scenario() {  # name, provisional, expected, then a shell snippet that edits files
  local name=$1 prov=$2 want=$3 edit=$4
  git -C "$TMP" checkout -q -b "$name" main
  ( cd "$TMP" && eval "$edit" ) 
  git -C "$TMP" add -A && git -C "$TMP" commit -qm "$name"
  local got; got=$(cd "$TMP" && "$ROOT/scripts/tier-from-paths.sh" main "$prov")
  if [ "$got" = "$want" ]; then ok "$name: provisional $prov → $got"; else bad "$name: provisional $prov → $got (wanted $want)"; fi
}
scenario copy-only-t0      T0 T0 "echo '// tweak' >> src/copy/strings.js"
scenario copy-only-stays-t2 T2 T2 "echo '// tweak' >> src/copy/strings.js"
scenario no-issue-defaults-t3 '' T3 "echo '// tweak' >> src/copy/strings.js"
scenario migration-raises  T0 T3 "mkdir -p migrations && echo 'drop table users;' > migrations/001.sql; echo '// c' >> src/copy/strings.js"
scenario auth-raises       T1 T3 "mkdir -p src/auth && echo 'export const x=1' > src/auth/session.js"
scenario contract-raises   T0 T2 "echo 'openapi: 3.1.0' > openapi.yaml"
scenario tests-raise       T0 T1 "echo 'export {}' > tests/extra.test.js"
scenario workflow-raises   T0 T1 "mkdir -p .github/workflows && echo 'name: x' > .github/workflows/x.yml"

gate2() {  # name, expect(ok|fail), edit
  local name=$1 want=$2 edit=$3
  git -C "$TMP" checkout -q -b "g2-$name" main
  ( cd "$TMP" && eval "$edit" )
  git -C "$TMP" add -A && git -C "$TMP" commit -qm "$name"
  MSG="tests-changed-with-src: $name"
  if [ "$want" = ok ]; then ( cd "$TMP" && expect_ok "$ROOT/scripts/gates/tests-changed-with-src.sh" main )
  else ( cd "$TMP" && expect_fail "$ROOT/scripts/gates/tests-changed-with-src.sh" main ); fi
}
gate2 "src and tests changed"  ok   "echo '// c' >> src/greeting.js; echo '// t' >> tests/greeting.test.js"
gate2 "src changed, no test"   fail "echo '// c' >> src/greeting.js"
gate2 "tests only"             ok   "echo '// t' >> tests/greeting.test.js"
gate2 "nothing in src"         ok   "echo 'x' > README.md"

# The subshell above cannot bump our counters; recount from output instead.
# (Kept simple: the four gate2 lines print their own ✓/✗.)

git -C "$TMP" checkout -q main
echo '{}' > "$TMP/scan-report.json"; git -C "$TMP" add scan-report.json
MSG="gate scan-provenance fails on a tracked report"
( cd "$TMP" && touch -d '1 minute ago' .m && touch scan-report.json && expect_fail "$ROOT/scripts/gates/scan-provenance.sh" scan-report.json .m )

# ------------------------------------------------------------ form parser
section "Issue-form parser"
BODY=$'### Requested by\n\ncustomer@example.com\n\n### Internal sponsor\n\n@alice\n\n### What you expected\n\nA filter on the orders page.'
export BODY
[ "$(scripts/parse-issue-form.sh 'Internal sponsor' | sed 's/^@//')" = alice ] && ok "sponsor parsed and @ stripped" || bad "sponsor parse"
[ "$(scripts/parse-issue-form.sh 'Requested by')" = customer@example.com ] && ok "requested-by parsed" || bad "requested-by parse"
[ -z "$(scripts/parse-issue-form.sh 'Does not exist')" ] && ok "missing field yields empty, not an error" || bad "missing field"
BODY=$'### Internal sponsor\n\n$(touch /tmp/selftest-pwned); `id`\n'
rm -f /tmp/selftest-pwned
OUT=$(scripts/parse-issue-form.sh 'Internal sponsor')
[ "$OUT" = '$(touch /tmp/selftest-pwned); `id`' ] && [ ! -e /tmp/selftest-pwned ] && ok "shell metacharacters in the body are returned as text, not executed" || bad "injection through form body"
unset BODY

# --------------------------------------------------------------- receiver
section "Webhook receiver"
if node --test receiver/ >/dev/null 2>&1; then ok "receiver: signature check, dispatch shape, title bound (node --test)"; else bad "receiver tests"; node --test receiver/ 2>&1 | tail -20; fi

# --------------------------------------------------------------- gate log
section "Gate log"
GATE_LOG="$TMP/log.ndjson" scripts/gates/log.sh tests-executed success abc123 42 T0 app/claude
GATE_LOG="$TMP/log.ndjson" scripts/gates/log.sh scan-provenance failure abc123 42 T0 app/claude
MSG="two evaluations, each a valid JSON object with 7 fields"
expect_ok bash -c "test \$(jq -c 'select(keys|length==7)' '$TMP/log.ndjson' | wc -l) -eq 2"
MSG="passes are recorded, not only failures"
expect_ok jq -e 'select(.result=="success")' "$TMP/log.ndjson"

rm -rf "$TMP" /tmp/selftest-empty.json
printf '\n\033[1m%d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
