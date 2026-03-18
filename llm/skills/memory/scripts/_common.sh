#!/usr/bin/env bash
# Common variables and helpers for memory scripts.
# Source this file; do not execute directly.

DB="$HOME/claude_memories.sqlite"
BLOB_DIR="$HOME/claude_memories"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sql_escape() {
  printf '%s' "${1//\'/\'\'}"
}

is_ascii() {
  # Returns 0 if the input is printable ASCII (plus newline and tab), 1 otherwise.
  if printf '%s' "$1" | LC_ALL=C grep -qP '[^\x20-\x7E\x0A\x09]'; then
    return 1
  fi
  return 0
}

ensure_db() {
  if [[ ! -f "$DB" ]]; then
    bash "$SCRIPT_DIR/setup-db.sh"
  fi
}
