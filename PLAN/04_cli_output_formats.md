# Step 4: CLI output formatting

## Goal

Refine the YAML and JSON output for `show` and `list` commands to be clean, token-light,
and human-readable. Add a `format` module in domain that centralizes output rendering
so both the CLI and future TUI can share the same serialization logic.

## Background

Step 3 wires the CLI to the database and produces output via `serde_yaml`/`serde_json`.
This step refines that output:

- YAML is the default because it's lighter on tokens and easier for humans to scan.
- JSON is available via `--format json` for agents that prefer structured parsing.
- The `list` output should include a summary header line on stderr (e.g.,
  `"3 tasks found"`) so the task data on stdout is clean for piping.
- `show` output for YAML should be easy to read: field order should be logical (id,
  title, status, then metadata).

The serialization functions already exist in `domain.rs` (`format_task_yaml`, etc.).
This step may refine them or add wrappers. The key goal is making the output
agent-friendly: YAML for token-light readability, JSON for structured consumption.

## Tests (write BEFORE implementation)

### Output formatting tests (functional core — pure string transforms)

1. **`test_format_single_task_yaml_field_order`**
   - Input: a Task with id=1, title="Build it", status=todo
   - Expected: YAML output has `id` before `title`, `title` before `status`
   - Why: logical field ordering for readability

2. **`test_format_single_task_json_is_valid`**
   - Input: a fully-populated Task
   - Expected: output parses as valid JSON and contains all fields
   - Why: JSON is machine-parseable

3. **`test_format_empty_list_yaml`**
   - Input: empty vec of Tasks
   - Expected: `"[]\n"` (YAML empty sequence)
   - Why: empty list produces valid YAML, not blank output

4. **`test_format_empty_list_json`**
   - Input: empty vec of Tasks
   - Expected: `"[]"` (JSON empty array)
   - Why: empty list produces valid JSON

5. **`test_format_list_yaml_contains_all_tasks`**
   - Input: vec of 2 tasks with titles "Alpha" and "Beta"
   - Expected: YAML contains both "Alpha" and "Beta"
   - Why: all tasks are serialized

6. **`test_format_summary_line_zero`**
   - Input: count = 0
   - Expected: `"0 tasks found"`
   - Why: zero case

7. **`test_format_summary_line_one`**
   - Input: count = 1
   - Expected: `"1 task found"`
   - Why: singular form

8. **`test_format_summary_line_many`**
   - Input: count = 5
   - Expected: `"5 tasks found"`
   - Why: plural form

9. **`test_format_task_yaml_tags_as_list`**
   - Input: task with tags `["alpha", "beta"]`
   - Expected: YAML output contains a list under `tags:` with both values
   - Why: tags should be a YAML sequence, not a comma-separated string

10. **`test_format_task_yaml_empty_optional_fields`**
    - Input: task with empty repo, plan, worktree, github_issue_url, no completed_at
    - Expected: empty strings render as `repo: ''` or `repo: ""` (not omitted), completed_at renders as `null`
    - Why: all fields are always present so agents can see the full schema

## Files to create

### `rust/agent-progress/src/domain/format.rs` (functional core)

```rust
use crate::domain::Task;

pub fn summary_line(count: usize) -> String {
    match count {
        0 => "0 tasks found".to_string(),
        1 => "1 task found".to_string(),
        n => format!("{n} tasks found"),
    }
}

pub fn render_yaml(task: &Task) -> Result<String, serde_yaml::Error> {
    serde_yaml::to_string(task)
}

pub fn render_json(task: &Task) -> Result<String, serde_json::Error> {
    serde_json::to_string_pretty(task)
}

pub fn render_list_yaml(tasks: &[Task]) -> Result<String, serde_yaml::Error> {
    serde_yaml::to_string(tasks)
}

pub fn render_list_json(tasks: &[Task]) -> Result<String, serde_json::Error> {
    serde_json::to_string_pretty(tasks)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{TaskBuilder, Status};

    // All 10 tests listed in the Tests section above.
}
```

## Files to edit

### `rust/agent-progress/src/domain.rs`

Convert `domain.rs` into a module directory or add `pub mod format;` if keeping it as a
single file with a submodule. The implementor should choose the cleanest approach —
either:
- Rename `domain.rs` → `domain/mod.rs` and add `domain/format.rs`
- Or keep `domain.rs` and use `#[path]` (less idiomatic — prefer the directory approach)

Also, wire the `summary_line` into the CLI's list command stderr output:
```rust
// In cli.rs run() function, after listing tasks:
eprintln!("{}", domain::format::summary_line(tasks.len()));
```

### `rust/agent-progress/src/cli.rs`

Update the `run()` dispatch to:
- Use `domain::format::render_yaml` / `render_json` for `show`
- Use `domain::format::render_list_yaml` / `render_list_json` for `list`
- Print the summary line to stderr for `list`
- Use the appropriate render function for `create` and `update` (they show the result)

## Acceptance criteria

- `cargo test` passes with all 10 new format tests green (plus all existing tests still pass)
- `cargo clippy` has no warnings
- `agent-progress list` prints task data to stdout and `"N tasks found"` to stderr
- YAML output always includes all fields (empty strings shown explicitly, not omitted)
- JSON output is pretty-printed and valid
- Empty lists produce `[]\n` (YAML) or `[]` (JSON), not blank output
- Summary line uses correct singular/plural

## Dependencies

Steps 0–3 — needs the CLI wiring and domain types.
