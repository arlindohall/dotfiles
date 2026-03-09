#!/usr/bin/env bash
# Usage: include-chain.sh <file>
# Extracts the include/extend/import/require lines from a source file to show its dependency chain.
set -euo pipefail
file="$1"
grep -nE "^\s*(include|extend|import|require|from|use |requires_ancestor)" "$file" || true
