#!/usr/bin/env bash
# Usage: save-blob.sh <memory_id> <filetype> <description> [content or - for stdin]
# Saves a blob file associated with an existing memory.
# filetype must be "md" or "json". Content is written to ~/agent_memories/.
# File is named with a hash prefix to avoid collisions. Never overwrites.
set -euo pipefail

source "$(dirname "$0")/_common.sh"
ensure_db

if [[ $# -lt 3 ]]; then
  echo "Usage: save-blob.sh <memory_id> <filetype> <description> [content or - for stdin]" >&2
  exit 1
fi

memory_id="$1"
filetype="$2"
description="$3"
shift 3

if [[ "$filetype" != "md" && "$filetype" != "json" ]]; then
  echo "ERROR: filetype must be 'md' or 'json', got '${filetype}'." >&2
  exit 1
fi

# Verify memory exists
exists=$(sqlite3 "$DB" "SELECT COUNT(*) FROM memories WHERE id = ${memory_id};")
if [[ "$exists" -eq 0 ]]; then
  echo "ERROR: Memory ${memory_id} does not exist. Create it first with save-memory.sh." >&2
  exit 1
fi

# Read content
if [[ $# -ge 1 && "$1" != "-" ]]; then
  content="$1"
else
  content="$(cat)"
fi

if [[ -z "$content" ]]; then
  echo "ERROR: Blob content cannot be empty." >&2
  exit 1
fi

# Write to temp file in blob dir (same filesystem for atomic mv)
mkdir -p "$BLOB_DIR"
tmpfile=$(mktemp "${BLOB_DIR}/.tmp.XXXXXX.${filetype}")

# Clean up temp file on error
trap 'rm -f "$tmpfile"' ERR

printf '%s' "$content" > "$tmpfile"

# Hash the file: try xxhsum, fall back to sha256sum
if command -v xxhsum &>/dev/null; then
  hash=$(xxhsum "$tmpfile" | awk '{print $1}')
elif command -v xxh64sum &>/dev/null; then
  hash=$(xxh64sum "$tmpfile" | awk '{print $1}')
else
  hash=$(sha256sum "$tmpfile" | cut -c1-16)
fi

filename="blob-${hash}.${filetype}"
target="${BLOB_DIR}/${filename}"

if [[ -f "$target" ]]; then
  # Content-addressed: same hash means same content, already saved
  rm -f "$tmpfile"
  # Check if this blob is already linked to this memory
  already=$(sqlite3 "$DB" "SELECT COUNT(*) FROM memory_blobs WHERE memory_id = ${memory_id} AND filename = '$(sql_escape "$filename")';")
  if [[ "$already" -eq 0 ]]; then
    escaped_desc="$(sql_escape "$description")"
    escaped_fn="$(sql_escape "$filename")"
    sqlite3 "$DB" "INSERT INTO memory_blobs(memory_id, filename, filetype, description) VALUES(${memory_id}, '${escaped_fn}', '${filetype}', '${escaped_desc}');" 2>/dev/null || true
  fi
  echo "Blob already exists: ${target}"
  exit 0
fi

mv "$tmpfile" "$target"

escaped_desc="$(sql_escape "$description")"
escaped_fn="$(sql_escape "$filename")"
sqlite3 "$DB" "INSERT INTO memory_blobs(memory_id, filename, filetype, description) VALUES(${memory_id}, '${escaped_fn}', '${filetype}', '${escaped_desc}');"

echo "Saved blob: ${target}"
