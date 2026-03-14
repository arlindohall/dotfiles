#!/usr/bin/env bash
# Usage: find-tests.sh <pattern> [search_root]
# Finds test files that reference <pattern>.
# Searches from search_root (default: current directory).
set -euo pipefail
pattern="$1"
root="${2:-.}"
grep -rln "$pattern" "$root" \
  --include="*.rb" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.go" --include="*.rs" \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=sorbet \
  --exclude-dir=.git --exclude-dir=tmp --exclude-dir=log \
  | grep -E "_test\.|_spec\.|\.test\.|\.spec\.|/test/|/spec/|/tests/" \
  || true
