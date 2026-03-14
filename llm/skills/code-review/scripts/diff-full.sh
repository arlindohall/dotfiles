#!/usr/bin/env bash
# Usage: diff-full.sh [base_ref]
# Shows the full unified diff of the change.
# Defaults to HEAD~1 if no base_ref is given.
set -euo pipefail
base="${1:-HEAD~1}"
git diff "$base" HEAD
