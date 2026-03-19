#!/usr/bin/env bash
set -euo pipefail

# run-touched-tests.sh — Run only the test files changed in the most recent commit.
#
# Usage:
#   run-touched-tests.sh [TEST_COMMAND]
#
# Arguments:
#   TEST_COMMAND   The test runner command (default: auto-detect from file extensions).
#                  Examples: "bin/rails test", "yarn test", "npx jest"
#
# Detects changed test files from HEAD, filters by common test-file patterns,
# and runs them with the given (or detected) test command.
#
# Exits 0 if no test files were touched (prints a warning — this may be a TDE violation).

# Check for git aliases
HAS_NAMES_ALIAS=$(git config --get alias.names 2>/dev/null || true)

if [[ -n "$HAS_NAMES_ALIAS" ]]; then
  CHANGED_FILES=$(git names)
else
  CHANGED_FILES=$(git show --name-only --pretty= HEAD)
fi

# Filter to test files
RUBY_TESTS=$(echo "$CHANGED_FILES" | grep '_test\.rb$' || true)
JS_TS_TESTS=$(echo "$CHANGED_FILES" | grep '\.test\.[jt]sx\?$' || true)

if [[ -z "$RUBY_TESTS" && -z "$JS_TS_TESTS" ]]; then
  echo "WARNING: No test files changed in HEAD. This may be a TDE violation." >&2
  exit 0
fi

if [[ $# -ge 1 ]]; then
  TEST_COMMAND="$1"
  shift
  ALL_TESTS=$(printf "%s\n%s" "$RUBY_TESTS" "$JS_TS_TESTS" | grep -v '^$')
  echo "$ALL_TESTS" | xargs $TEST_COMMAND "$@"
else
  # Auto-detect: run each type with its conventional runner
  if [[ -n "$RUBY_TESTS" ]]; then
    echo "$RUBY_TESTS" | xargs bin/rails test
  fi
  if [[ -n "$JS_TS_TESTS" ]]; then
    echo "$JS_TS_TESTS" | xargs yarn test
  fi
fi
