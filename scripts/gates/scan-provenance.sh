#!/usr/bin/env bash
# Gate: the scan report was written by this job and is not something a
# commit could have carried in.
# Usage: scan-provenance.sh <report> <marker-file>
set -euo pipefail
REPORT="$1"; MARKER="$2"
if [ ! -f "$REPORT" ]; then
  echo "::error::$REPORT does not exist."; exit 1
fi
if [ ! "$REPORT" -nt "$MARKER" ]; then
  echo "::error::$REPORT predates this job."; exit 1
fi
if git ls-files --error-unmatch "$REPORT" >/dev/null 2>&1; then
  echo "::error::$REPORT is tracked. A report an agent can commit is a report an agent can forge."
  exit 1
fi
echo "scan report is from this run"
