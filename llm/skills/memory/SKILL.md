---
name: memory
description: >
  Persistent agent memory via SQLite. Save and retrieve facts, preferences,
  project context, and large documents across sessions. Use to remember
  important information the user shares and to recall it when relevant.
---

# Agent Memory

Persistent memory across Claude Code sessions. Data lives in `~/agent_memories.sqlite`
with overflow blob storage in `~/agent_memories/`.

Helper scripts are in [scripts/](scripts/). Run them with `bash` from the skill directory.

## When to Save Memories

Save a memory when:
- The user states a preference or personal fact ("I prefer tabs", "deploy target is us-east-1")
- Important project context is established (repo conventions, architecture decisions)
- The user explicitly asks you to remember something
- A non-obvious discovery is made that would be useful in future sessions

Do NOT save ephemeral or trivially re-derivable information.

## When to Look Up Memories

Look up memories when:
- At the start of a session, check for memories related to the current project or directory
- Before making assumptions about user preferences
- When the user references something that might have been stored previously
- When the user asks "do you remember..." or similar

## Workflow: Save a Memory

1. Compose concise ASCII content (one to three sentences, one fact per memory).
2. Choose 2-5 descriptive lowercase keywords (hyphenate multi-word: `fish-shell`, `deploy-config`).
3. Run:
   ```
   bash ./scripts/save-memory.sh "User prefers pytest over unittest for all Python projects" python testing pytest preferences
   ```
4. If content is too large or needs formatting, save a short summary as the memory, then attach a blob.

## Workflow: Look Up Memories

1. Run:
   ```
   bash ./scripts/lookup-memory.sh "python"
   ```
2. Review results and incorporate relevant context into your response.
3. If a memory has blobs, use `blob-info.sh` to check size before reading.

## Workflow: Save a Blob

Use blobs sparingly -- only when content is too large for a memory or needs rich formatting.

1. Ensure a parent memory exists (or create one with `save-memory.sh`).
2. Run:
   ```
   bash ./scripts/save-blob.sh <memory_id> md "Detailed architecture notes" "# Architecture\n..."
   ```
   Or pipe content from stdin:
   ```
   cat notes.md | bash ./scripts/save-blob.sh <memory_id> md "Detailed architecture notes" -
   ```
3. Only `md` and `json` filetypes are supported.

## Workflow: Inspect a Blob

1. Run:
   ```
   bash ./scripts/blob-info.sh <memory_id>
   ```
2. Review the file size before deciding to read the full blob into context.
3. If reasonably sized, read the blob file directly at the path shown.

## Setup

If the database does not exist, any script will create it automatically. To set up manually:
```
bash ./scripts/setup-db.sh
```

## Key Principles

1. **Keep it short.** One memory = one fact or preference. A sentence or two, not paragraphs.
2. **Use descriptive keywords.** Think about what future-you would search for.
3. **ASCII only for memories.** Use blobs for anything needing rich formatting.
4. **No duplicates.** Look up before saving to avoid redundant entries.
5. **Be specific.** "user prefers pytest over unittest" beats "user has testing preferences".
6. **Blobs are rare.** Most knowledge fits in a plaintext memory.
