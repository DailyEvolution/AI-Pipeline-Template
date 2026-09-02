#!/usr/bin/env bash
# Usage: tier-from-paths.sh <base-ref> [provisional-tier]
# Prints the tier. A path can raise the tier; nothing lowers it.
# Path rules mirror docs/tiers.md. Change both together.
set -euo pipefail
BASE="$1"; TIER="${2:-T3}"

raise() { case "$TIER$1" in T0T1|T0T2|T0T3|T1T2|T1T3|T2T3) TIER=$1;; esac; }

FILES=$(git diff --name-only "$BASE"...HEAD)
echo "$FILES" | grep -qE '^(migrations|db)/'                  && raise T3
echo "$FILES" | grep -qE '^src/(auth|billing)/'               && raise T3
echo "$FILES" | grep -qE '^(openapi\.yaml|src/api/contracts/)' && raise T2
echo "$FILES" | grep -qE '^(tests|\.github)/'                 && raise T1
echo "$TIER"
