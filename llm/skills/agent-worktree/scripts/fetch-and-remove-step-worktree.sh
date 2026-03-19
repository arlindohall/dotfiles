#!/usr/bin/env bash
set -euo pipefail

# fetch-and-remove-step-worktree.sh — Fetch the implementor's step branch into the
# orchestrator worktree, then remove the implementor worktree.
#
# Usage:
#   fetch-and-remove-step-worktree.sh <ORCH_WORKTREE> <PLAN_HANDLE> <STEP_ID>
#
# This should be run immediately after an implementor returns, before spawning
# the reviewer.

if [[ $# -ne 3 ]]; then
  echo "Usage: fetch-and-remove-step-worktree.sh <ORCH_WORKTREE> <PLAN_HANDLE> <STEP_ID>" >&2
  exit 1
fi

ORCH_WORKTREE="$1"
PLAN_HANDLE="$2"
STEP_ID="$3"

STEP_BRANCH="orch-${PLAN_HANDLE}-step-${STEP_ID}"
STEP_WORKTREE="${ORCH_WORKTREE}-step${STEP_ID}"

cd "${ORCH_WORKTREE}"
git fetch . "${STEP_BRANCH}"
git worktree remove "${STEP_WORKTREE}" --force
