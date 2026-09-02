#!/usr/bin/env bash
# Usage: BODY="<issue body>" parse-issue-form.sh "<Field label>"
# Issue forms render each field as "### <Label>" followed by its value.
# Prints the first non-empty line of that field, or nothing.
# The body arrives through the environment, never as an argument, so a
# body containing shell metacharacters is still just text.
set -euo pipefail
printf '%s\n' "${BODY:-}" | awk -v h="### $1" \
  '$0==h {f=1; next}  /^### / {f=0}  f && NF {print; exit}'
