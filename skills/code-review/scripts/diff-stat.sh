#!/usr/bin/env bash
# Usage: diff-stat.sh [base_ref]
# Shows the file-level summary of what changed.
# Defaults to HEAD~1 if no base_ref is given.
set -euo pipefail
base="${1:-HEAD~1}"
git diff "$base" HEAD --stat
