#!/usr/bin/env bash
set -euo pipefail

# run-in-worktree-env.sh — Run a command in a worktree using the original project's
# shadowenv / dev environment.
#
# Usage:
#   run-in-worktree-env.sh <ORIGINAL_PROJECT_DIR> <WORKTREE_DIR> -- <COMMAND...>
#
# Problem: shadowenv / dev environments are keyed to a specific directory. A new git
# worktree at a different path won't inherit the environment. This script captures
# GEM_HOME, GEM_PATH, BUNDLE_APP_CONFIG, and PATH from the original project's
# shadowenv and exports them into the worktree before running the command.
#
# Example:
#   run-in-worktree-env.sh /path/to/project /path/to/worktree -- bin/rails test test/foo_test.rb

if [[ $# -lt 4 ]] || [[ "$3" != "--" ]]; then
  echo "Usage: run-in-worktree-env.sh <ORIGINAL_PROJECT_DIR> <WORKTREE_DIR> -- <COMMAND...>" >&2
  exit 1
fi

ORIGINAL_DIR="$1"
WORKTREE_DIR="$2"
shift 3  # past ORIGINAL_DIR, WORKTREE_DIR, and "--"

# Capture environment from the original project directory
GEM_HOME_VAL=$(cd "$ORIGINAL_DIR" && shadowenv exec -- printenv GEM_HOME 2>/dev/null || true)
GEM_PATH_VAL=$(cd "$ORIGINAL_DIR" && shadowenv exec -- printenv GEM_PATH 2>/dev/null || true)
BUNDLE_APP_CONFIG_VAL=$(cd "$ORIGINAL_DIR" && shadowenv exec -- printenv BUNDLE_APP_CONFIG 2>/dev/null || true)
ORIG_PATH_VAL=$(cd "$ORIGINAL_DIR" && shadowenv exec -- printenv PATH 2>/dev/null || true)

cd "$WORKTREE_DIR"

export GEM_HOME="${GEM_HOME_VAL}"
export GEM_PATH="${GEM_PATH_VAL}"
export BUNDLE_APP_CONFIG="${BUNDLE_APP_CONFIG_VAL}"
export PATH="${ORIG_PATH_VAL}"

exec "$@"
