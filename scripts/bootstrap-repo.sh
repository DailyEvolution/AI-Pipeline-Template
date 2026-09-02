#!/usr/bin/env bash
# One-time repository bootstrap. Requires gh, authenticated, run from the
# repository root. Re-runnable: every step is idempotent.
set -euo pipefail
ORG="${1:?usage: bootstrap-repo.sh <org> <repo>}"
REPO="${2:?usage: bootstrap-repo.sh <org> <repo>}"

# Labels every workflow assumes.
LABELS=(
  "pipeline:heal|1F6152|Filed from a runtime error signal"
  "pipeline:improve|1F6152|Filed from the in-product request surface"
  "pipeline:halt|A34B18|STOP. Any open issue with this label halts every loop."
  "needs-sponsor|A8791A|No internal sponsor yet. Nothing acts on this."
  "tier:unclassified|D6D5C9|Not yet classified"
  "tier:T0|1F6152|Reversible by revert alone"
  "tier:T1|4A7A3C|Reversible by revert plus a deploy"
  "tier:T2|A8791A|Reversible only with a compensating action"
  "tier:T3|A34B18|Not reversible. Humans only."
  "incident|A34B18|An escaped defect. Closing it runs the Learn loop."
)
for entry in "${LABELS[@]}"; do
  IFS='|' read -r name color desc <<< "$entry"
  gh label create "$name" --color "$color" --description "$desc" --force
done
# fp:<id> labels are created on demand by heal-intake.yml.

# The code-owner team. Org admin required; harmless if it exists.
gh api "orgs/$ORG/teams" -f name=pipeline-owners -f privacy=closed >/dev/null || true

# Squash only, delete branches, allow auto-merge for humans on T1 PRs.
gh repo edit "$ORG/$REPO" \
  --enable-squash-merge \
  --enable-merge-commit=false \
  --enable-rebase-merge=false \
  --delete-branch-on-merge \
  --enable-auto-merge

# Rulesets. review.json needs the pipeline app id substituted first.
APP_ID="${PIPELINE_APP_ID:?set PIPELINE_APP_ID to the pipeline app ID}"
gh api -X POST "repos/$ORG/$REPO/rulesets" --input rulesets/checks.json
sed "s/\"<PIPELINE_APP_ID>\"/$APP_ID/" rulesets/review.json \
  | gh api -X POST "repos/$ORG/$REPO/rulesets" --input -
echo "bootstrap complete"
