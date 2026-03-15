#!/usr/bin/env bash
# Usage: blob-info.sh <memory_id>
# Shows blob metadata for a given memory: filename, type, size, description.
# Does not output blob content (use the file path to read it directly).
set -euo pipefail

source "$(dirname "$0")/_common.sh"
ensure_db

if [[ $# -lt 1 ]]; then
  echo "Usage: blob-info.sh <memory_id>" >&2
  exit 1
fi

memory_id="$1"

results=$(sqlite3 -separator '|' "$DB" "
  SELECT filename, filetype, description
  FROM memory_blobs
  WHERE memory_id = ${memory_id}
  ORDER BY created_at;
")

if [[ -z "$results" ]]; then
  echo "No blobs found for memory ${memory_id}."
  exit 0
fi

while IFS='|' read -r filename filetype description; do
  filepath="${BLOB_DIR}/${filename}"
  if [[ -f "$filepath" ]]; then
    size=$(du -h "$filepath" | cut -f1)
  else
    size="MISSING"
  fi
  echo "Blob: ${filename} (${filetype}, ${size})"
  echo "Description: ${description}"
  echo "Path: ${filepath}"
  echo ""
done <<< "$results"
