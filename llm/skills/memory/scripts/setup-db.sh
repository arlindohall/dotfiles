#!/usr/bin/env bash
# Usage: setup-db.sh
# Creates the claude_memories.sqlite database and all tables if they do not exist.
# Also creates ~/claude_memories/ directory for blob storage.
# Safe to run multiple times (idempotent).
set -euo pipefail

source "$(dirname "$0")/_common.sh"

mkdir -p "$BLOB_DIR"

sqlite3 "$DB" <<'SQL'
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS memories (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    content     TEXT NOT NULL CHECK(length(content) > 0),
    created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS memory_keywords (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    memory_id   INTEGER NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
    keyword     TEXT NOT NULL CHECK(length(keyword) > 0),
    UNIQUE(memory_id, keyword)
);

CREATE INDEX IF NOT EXISTS idx_keywords_keyword ON memory_keywords(keyword);
CREATE INDEX IF NOT EXISTS idx_keywords_memory_id ON memory_keywords(memory_id);

CREATE TABLE IF NOT EXISTS memory_blobs (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    memory_id   INTEGER NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
    filename    TEXT NOT NULL UNIQUE,
    filetype    TEXT NOT NULL CHECK(filetype IN ('md', 'json')),
    description TEXT NOT NULL DEFAULT '',
    created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_blobs_memory_id ON memory_blobs(memory_id);
SQL

echo "Memory database ready: $DB" >&2
