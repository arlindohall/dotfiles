#!/usr/bin/env bash
# Usage: changed-files.sh [base_ref]
# Lists the paths of files changed in the commit, one per line.
# Defaults to HEAD~1 if no base_ref is given.
set -euo pipefail
base="${1:-HEAD~1}"
git diff "$base" HEAD --name-only
