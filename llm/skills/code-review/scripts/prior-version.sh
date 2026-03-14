#!/usr/bin/env bash
# Usage: prior-version.sh <file> [base_ref]
# Shows the version of <file> before the change, using git show.
# Defaults to HEAD~1 if no base_ref is given.
set -euo pipefail
file="$1"
base="${2:-HEAD~1}"
git show "${base}:${file}" 2>/dev/null || echo "(file did not exist at ${base})"
