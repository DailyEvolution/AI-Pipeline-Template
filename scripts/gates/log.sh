#!/usr/bin/env bash
# Append one gate evaluation, pass or fail, to gate-log.ndjson.
# Usage: log.sh <gate> <result> <sha> <pr> <tier> <actor>
set -euo pipefail
jq -nc \
  --arg gate   "$1" --arg result "$2" --arg sha  "$3" \
  --arg pr     "$4" --arg tier   "$5" --arg actor "$6" \
  --arg ts     "$(date -u +%FT%TZ)" \
  '$ARGS.named' >> "${GATE_LOG:-gate-log.ndjson}"
