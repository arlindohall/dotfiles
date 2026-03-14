#!/usr/bin/env bash
# Usage: find-callers.sh <pattern> [search_root]
# Finds files that reference <pattern> in source code (excludes tests, vendored code, generated files).
# Searches from search_root (default: current directory).
set -euo pipefail
pattern="$1"
root="${2:-.}"
grep -rn "$pattern" "$root" \
  --include="*.rb" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.go" --include="*.rs" --include="*.erb" --include="*.haml" \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=sorbet \
  --exclude-dir=.git --exclude-dir=tmp --exclude-dir=log \
  | grep -v "_test\.\|_spec\.\|\.test\.\|\.spec\.\|/test/\|/spec/\|/tests/" \
  || true
