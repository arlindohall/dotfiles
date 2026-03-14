#!/usr/bin/env bash
# Usage: memoization-check.sh <file>
# Scans a file for methods that might benefit from memoization:
# methods with no instance variable assignment (||=) that perform non-trivial work
# (parsing, decoding, I/O, building objects).
# Prints method signatures that lack memoization alongside any existing memoized methods.
set -euo pipefail
file="$1"
echo "=== Methods with memoization (||=) ==="
grep -n "||=" "$file" || echo "(none)"
echo ""
echo "=== All method definitions ==="
grep -n "^\s*def " "$file" || echo "(none)"
