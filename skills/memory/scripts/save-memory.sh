#!/usr/bin/env bash
# Usage: save-memory.sh <content> <keyword1> [keyword2] [keyword3] ...
#        echo "content" | save-memory.sh - <keyword1> [keyword2] ...
# Saves a plaintext memory and indexes it under one or more keywords.
# Content must be ASCII text. At least one keyword is required.
set -euo pipefail

source "$(dirname "$0")/_common.sh"
ensure_db

if [[ $# -lt 2 ]]; then
  echo "Usage: save-memory.sh <content|-  for stdin> <keyword1> [keyword2...]" >&2
  exit 1
fi

content="$1"
shift

if [[ "$content" == "-" ]]; then
  content="$(cat)"
fi

if [[ -z "$content" ]]; then
  echo "ERROR: Memory content cannot be empty." >&2
  exit 1
fi

if ! is_ascii "$content"; then
  echo "ERROR: Memory content must be ASCII text. Use save-blob.sh for rich content." >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "ERROR: At least one keyword is required." >&2
  exit 1
fi

escaped_content="$(sql_escape "$content")"

memory_id=$(sqlite3 "$DB" "
  INSERT INTO memories(content) VALUES('${escaped_content}');
  SELECT last_insert_rowid();
")

keywords_list=""
for kw in "$@"; do
  escaped_kw="$(sql_escape "$kw")"
  sqlite3 "$DB" "INSERT OR IGNORE INTO memory_keywords(memory_id, keyword) VALUES(${memory_id}, '${escaped_kw}');"
  if [[ -n "$keywords_list" ]]; then
    keywords_list="${keywords_list}, ${kw}"
  else
    keywords_list="${kw}"
  fi
done

echo "Saved memory ${memory_id} with keywords: ${keywords_list}"
