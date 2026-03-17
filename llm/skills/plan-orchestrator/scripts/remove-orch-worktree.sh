#!/usr/bin/env bash
set -euo pipefail

# remove-orch-worktree.sh — Remove the orchestrator worktree during final cleanup.
#
# Usage:
#   remove-orch-worktree.sh <REPO_ROOT> <ORCH_WORKTREE>

if [[ $# -ne 2 ]]; then
  echo "Usage: remove-orch-worktree.sh <REPO_ROOT> <ORCH_WORKTREE>" >&2
  exit 1
fi

REPO_ROOT="$1"
ORCH_WORKTREE="$2"

cd "${REPO_ROOT}"
git worktree remove "${ORCH_WORKTREE}" --force
