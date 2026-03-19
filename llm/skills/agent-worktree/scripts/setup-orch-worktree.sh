#!/usr/bin/env bash
set -euo pipefail

# setup-orch-worktree.sh — Create an orchestrator worktree and branch for plan execution.
#
# Usage:
#   setup-orch-worktree.sh <PLAN_HANDLE> [PROJECT_NAME]
#
# Arguments:
#   PLAN_HANDLE      A short, hyphenated slug derived from the plan's goal
#                  (e.g. "add-docker-support").
#   PROJECT_NAME   Optional. Defaults to a name derived from the current directory.
#
# Creates:
#   - Branch: orch-<PLAN_HANDLE>
#   - Worktree: ../<PROJECT_NAME>-orch-<PLAN_HANDLE>/
#
# Outputs (to stdout):
#   REPO_ROOT, PROJECT_NAME, PLAN_HANDLE, ORCH_BRANCH, ORCH_WORKTREE — one per line,
#   as KEY=VALUE pairs suitable for eval.

if [[ $# -lt 1 ]]; then
  echo "Usage: setup-orch-worktree.sh <PLAN_HANDLE> [PROJECT_NAME]" >&2
  exit 1
fi

PLAN_HANDLE="$1"
REPO_ROOT=$(git rev-parse --show-toplevel)

# In a monorepo, $(basename "$REPO_ROOT") may return a generic name like "src".
# Derive PROJECT_NAME from the zone/project directory instead if not provided.
if [[ $# -ge 2 ]]; then
  PROJECT_NAME="$2"
else
  PROJECT_NAME=$(basename "$(pwd | sed 's|/[^/]*/[^/]*$||')")
fi

ORCH_BRANCH="orch-${PLAN_HANDLE}"
ORCH_WORKTREE="${REPO_ROOT}/../${PROJECT_NAME}-orch-${PLAN_HANDLE}"

git branch "${ORCH_BRANCH}"
git worktree add "${ORCH_WORKTREE}" "${ORCH_BRANCH}"

echo "REPO_ROOT=${REPO_ROOT}"
echo "PROJECT_NAME=${PROJECT_NAME}"
echo "PLAN_HANDLE=${PLAN_HANDLE}"
echo "ORCH_BRANCH=${ORCH_BRANCH}"
echo "ORCH_WORKTREE=${ORCH_WORKTREE}"
