#!/usr/bin/env bash
# Usage: lookup-memory.sh <keyword>
# Looks up all memories matching the given keyword (case-insensitive substring match).
# Prints memory ID, content, all keywords, and blob count for each match.
set -euo pipefail

source "$(dirname "$0")/_common.sh"
ensure_db

if [[ $# -lt 1 ]]; then
  echo "Usage: lookup-memory.sh <keyword>" >&2
  exit 1
fi

keyword="$(sql_escape "$1")"

results=$(sqlite3 -separator '|' "$DB" "
  SELECT
    m.id,
    m.content,
    m.created_at,
    (SELECT GROUP_CONCAT(mk2.keyword, ', ')
     FROM memory_keywords mk2
     WHERE mk2.memory_id = m.id) as all_keywords,
    (SELECT COUNT(*)
     FROM memory_blobs mb
     WHERE mb.memory_id = m.id) as blob_count
  FROM memories m
  JOIN memory_keywords mk ON mk.memory_id = m.id
  WHERE mk.keyword LIKE '%${keyword}%' COLLATE NOCASE
  GROUP BY m.id
  ORDER BY m.created_at DESC;
")

if [[ -z "$results" ]]; then
  echo "No memories found for keyword: $1"
  exit 0
fi

while IFS='|' read -r id content created_at all_keywords blob_count; do
  echo "[id:${id}] (${created_at}) (keywords: ${all_keywords})"
  echo "${content}"
  if [[ "$blob_count" -gt 0 ]]; then
    echo "Blobs: ${blob_count}"
  fi
  echo ""
done <<< "$results"
