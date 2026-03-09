---
name: code-review
description: >
  Produces a thorough written code review of the current checked-out commit (or a specified commit/range).
  Generates a REVIEW.md with feedback on goals, implementation quality, correctness, test coverage,
  performance, and gaps. Use when asked to review a PR, commit, diff, or code change.
---

# Code Review

Generate a structured, publication-quality `REVIEW.md` for a code change. The review must be
specific — reference files and line numbers, and include concrete alternative code snippets
where improvements are suggested.

This skill uses custom tools from the `pi-code-review` package. Call them by name
(e.g., `commit_info`, `diff_stat`). They accept simple parameters and return
pre-filtered output.

## Workflow

Follow these phases in order. Each phase builds context for the next. Do not skip phases.

### Phase 1: Identify the Change

Determine what changed and why.

1. `commit_info` — get the commit hash, author, date, subject, body, and linked issue.
2. `diff_stat` — get the file-level change summary.
3. `diff_full` — get the full unified diff.
4. `changed_files` — get the list of changed file paths (for iteration in later phases).

If the user specifies a different base ref, pass it as the `base` parameter to each tool.

Extract from phase 1:
- Commit hash, author, date
- Linked issue or PR URL (from the commit body)
- Stated intent (from the commit subject and body)
- List of changed files with rough change size per file

### Phase 2: Read the Changed Files in Full

For every file from `changed_files`, use the `read` tool to read the **entire current version**.
Do not rely on diff hunks alone — you need surrounding context to evaluate correctness.

If you also need the version before the change (e.g., to understand what was removed):
use `prior_version` with the file path.

### Phase 3: Map the Dependency Graph

For each changed file, trace its callers, callees, includes, and type dependencies. The goal is to
understand **how the changed code is reached at runtime** and **what else it affects**.

1. `include_chain` — see what a file includes/imports/extends.
2. `find_callers` — find non-test code that references a symbol.
3. `count_calls` — count total call sites for a symbol to gauge how hot a code path is.

Repeat for every significant symbol introduced or modified by the diff.

Identify from phase 3:
- All call sites of the changed functions/methods
- The include/import chain (what modules are mixed in transitively?)
- The end-user surface (view template, API endpoint, CLI command, etc.)
- Related code that does similar things (for consistency checks)
- Feature flags or config that gate the behavior

### Phase 4: Read Pre-existing Tests

Find and read the **full test files** for every changed file, plus closely related test files.

1. `find_tests` — find test files that reference a symbol.
2. Use the `read` tool to read each test file in full (not just the new lines from the diff).

Understand from phase 4:
- What was already tested before this change?
- What new tests were added?
- Do the new tests overlap with pre-existing coverage?
- Are there test gaps?

### Phase 5: Analyze for Issues

With full context from phases 1–4, systematically evaluate each of these dimensions:

#### 5a. Correctness
- Does the implementation achieve the stated goal?
- Are there edge cases not handled? (null/empty inputs, error paths, concurrent access, race conditions)
- Does the code depend on subtle ordering or side effects? Is that fragile?
- Are type signatures accurate? Do runtime casts (`T.cast`, `T.unsafe`, `as`, `!`) hide real mismatches?

#### 5b. Consistency
- Does the change follow existing patterns in the codebase?
- If this change is part of a migration, are there remaining un-migrated call sites?
- Are naming conventions consistent?

#### 5c. Performance
- Is any work repeated unnecessarily per request/call? (Missing memoization, redundant I/O, repeated parsing)
- Use `count_calls` to quantify how many times key functions fire per user operation.
- Use `memoization_check` to see which methods in a file are and aren't memoized.
- Does the change increase latency on a hot path?
- Are there N+1 query patterns, unbounded loops, or unnecessary allocations?

#### 5d. Test Quality
- Do tests assert the **actual behavior under test**, or just assert no crash (`assert_response :ok`)?
- Do integration tests verify that values reach the end user (rendered HTML, API response body), or only internal state?
- Are test descriptions accurate? Does the test body match what the test name claims?
- Is there excessive mocking that hides real integration bugs?
- Are error/failure paths tested?
- Are pre-existing test issues worth flagging (even if not introduced by this PR)?

#### 5e. Design and Maintainability
- Are implicit dependencies documented or enforced? (e.g., `requires_ancestor`, explicit parameters vs. `self` casts)
- Is the abstraction level appropriate? (Too many layers? Too few?)
- Will future developers understand why this change was made?

### Phase 6: Write REVIEW.md

Produce the review document with this structure:

```markdown
# Code Review: `<commit subject>`

**Commit:** `<hash>`
**Author:** <name>
**Date:** <date>
**Issue:** <link if available>

---

## Summary of Change
<1–3 sentences: what changed and why>

---

## Desired Outcome
<What the change is trying to accomplish, written from the user/system perspective>

---

## What the Implementation Does Well
<Specific positives, with file:line references. Explain WHY each is good.>

---

## Gaps and Issues
<Numbered list. Each issue includes:>
### N. <Issue title>
**File:** `<path>`, lines X–Y
<Explanation of the problem>
<Why it matters (correctness, performance, maintainability, etc.)>
**Suggested fix:**
\`\`\`language
<concrete code snippet showing the alternative>
\`\`\`

---

## Test Coverage Assessment
<A table or matrix showing scenarios vs test layers (unit, integration, e2e, TS/JS).
Use ✅, ⚠️, ❌ to indicate coverage quality.>

---

## Performance Concerns
<If any: quantify the impact (e.g., "called N times per request"), explain the cost,
and suggest a fix with a code snippet.>

---

## Minor Observations
<Bullet list of smaller issues: style, naming, pre-existing bugs, test smells.
These are things the author might want to know but that don't block merge.>

---

## Summary Verdict
<2–4 sentences: is the change correct? Is the test suite adequate? What is the single
most important thing to address before merge?>
```

## Key Principles

1. **Read before judging.** Never critique code you haven't read in full with surrounding context.
2. **Trace to the user.** Understand how the changed code reaches the end user before evaluating it.
3. **Count calls.** For anything on a hot path, use `count_calls` to quantify execution frequency.
4. **Assert what matters.** Flag tests that assert `ok` without checking the actual output value.
5. **Show, don't just tell.** Every suggested improvement must include a concrete code snippet.
6. **Distinguish PR issues from pre-existing issues.** Flag both, but label pre-existing ones clearly.
7. **Be specific.** Reference files and line numbers. Never say "this could be improved" without showing how.
