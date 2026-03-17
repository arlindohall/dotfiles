#!/usr/bin/env bash
set -euo pipefail

# rebase-step.sh — Rebase an approved step branch onto the orchestrator branch
# and fast-forward merge it, maintaining linear history.
#
# Usage:
#   rebase-step.sh <ORCH_WORKTREE> <ORCH_BRANCH> <PLAN_SLUG> <STEP_ID>
#
# After merging, the step branch is deleted. Tests should be run separately
# after this script completes to verify the invariant still holds.

if [[ $# -ne 4 ]]; then
  echo "Usage: rebase-step.sh <ORCH_WORKTREE> <ORCH_BRANCH> <PLAN_SLUG> <STEP_ID>" >&2
  exit 1
fi

ORCH_WORKTREE="$1"
ORCH_BRANCH="$2"
PLAN_SLUG="$3"
STEP_ID="$4"

STEP_BRANCH="orch-${PLAN_SLUG}-step-${STEP_ID}"

cd "${ORCH_WORKTREE}"
git rebase "${ORCH_BRANCH}" "${STEP_BRANCH}"
git checkout "${ORCH_BRANCH}"
git merge --ff-only "${STEP_BRANCH}"
git branch -d "${STEP_BRANCH}"
