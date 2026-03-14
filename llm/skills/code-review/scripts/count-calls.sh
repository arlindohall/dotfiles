#!/usr/bin/env bash
# Usage: count-calls.sh <pattern> [search_root]
# Counts how many times <pattern> appears in non-test source files.
# Useful for gauging how hot a code path is (e.g., how many call sites invoke a method per request).
set -euo pipefail
pattern="$1"
root="${2:-.}"
echo "=== Call sites (non-test) ==="
grep -rn "$pattern" "$root" \
  --include="*.rb" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.go" --include="*.rs" --include="*.erb" --include="*.haml" \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=sorbet \
  --exclude-dir=.git --exclude-dir=tmp --exclude-dir=log \
  | grep -v "_test\.\|_spec\.\|\.test\.\|\.spec\.\|/test/\|/spec/\|/tests/" \
  | tee /dev/stderr \
  | wc -l | xargs echo "Total:"
