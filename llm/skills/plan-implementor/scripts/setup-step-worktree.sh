#!/usr/bin/env bash
set -euo pipefail

# setup-step-worktree.sh — Create an implementor worktree and branch for a plan step.
#
# Usage:
#   setup-step-worktree.sh <REPO_ROOT> <ORCH_WORKTREE> <ORCH_BRANCH> <PLAN_SLUG> <STEP_ID>
#
# Arguments:
#   REPO_ROOT      The original repository root path.
#   ORCH_WORKTREE  The orchestrator's worktree path.
#   ORCH_BRANCH    The orchestrator's branch name.
#   PLAN_SLUG      Short hyphenated slug identifying the plan (e.g. "add-docker-support").
#   STEP_ID        The step identifier (e.g. "01", "02", "05").
#
# Creates:
#   - Branch: orch-<PLAN_SLUG>-step-<STEP_ID>
#   - Worktree: <ORCH_WORKTREE>-step<STEP_ID>/
#
# Outputs (to stdout):
#   WORKTREE and BRANCH — one per line, as KEY=VALUE pairs suitable for eval.

if [[ $# -ne 5 ]]; then
  echo "Usage: setup-step-worktree.sh <REPO_ROOT> <ORCH_WORKTREE> <ORCH_BRANCH> <PLAN_SLUG> <STEP_ID>" >&2
  exit 1
fi

REPO_ROOT="$1"
ORCH_WORKTREE="$2"
ORCH_BRANCH="$3"
PLAN_SLUG="$4"
STEP_ID="$5"

WORKTREE="${ORCH_WORKTREE}-step${STEP_ID}"
BRANCH="orch-${PLAN_SLUG}-step-${STEP_ID}"

cd "${REPO_ROOT}"
git worktree add "${WORKTREE}" -b "${BRANCH}" "${ORCH_BRANCH}"

echo "WORKTREE=${WORKTREE}"
echo "BRANCH=${BRANCH}"
