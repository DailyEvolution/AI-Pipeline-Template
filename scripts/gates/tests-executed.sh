#!/usr/bin/env bash
# Gate: the suite ran, and it ran something.
# Usage: tests-executed.sh <report.json>
set -euo pipefail
COUNT=$(jq '.numTotalTests // 0' "$1")
echo "tests executed: $COUNT"
if [ "$COUNT" -lt 1 ]; then
  echo "::error::Suite exited 0 having run no tests."
  exit 1
fi
