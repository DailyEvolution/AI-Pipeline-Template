#!/usr/bin/env bash
# Gate: a behaviour change arrives with a behaviour test.
# Usage: tests-changed-with-src.sh <base-ref>
set -euo pipefail
BASE="$1"
SRC=$(git diff --name-only "$BASE"...HEAD -- 'src/**' | wc -l)
TST=$(git diff --name-only "$BASE"...HEAD -- 'tests/**' | wc -l)
echo "src files changed: $SRC, test files changed: $TST"
if [ "$SRC" -gt 0 ] && [ "$TST" -eq 0 ]; then
  echo "::error::Source changed with no test change."
  exit 1
fi
