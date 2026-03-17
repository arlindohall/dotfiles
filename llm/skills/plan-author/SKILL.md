---
name: plan-author
description: >
  Authors a PLAN.md and PLAN/ directory of numbered step files that describe a multi-step
  code change. Each step targets a single commit of ~50–100 lines, with unit-tested
  functional-core code. Use when asked to "plan", "write a plan", "create a plan", or
  "break this into steps". Produces files that the plan-orchestrator and plan-implementor
  skills can execute.
version: 0.1.0
---

# Plan Author

You produce implementation plans — not code. Your output is a `PLAN.md` file and a
`PLAN/` directory of numbered step files. Another agent (or a human) will implement
each step later. Your job is to make each step so clear and self-contained that an
implementor can work from it without asking questions.

## When to use this skill

Use this skill when the user asks you to plan, break down, or decompose a code change
into steps. The user will describe what they want — possibly with diagrams, references
to existing code, or just a prose description. You turn that into a structured plan.

## Workflow

Follow these phases in order. Do not skip phases.

### Phase 1: Understand the request

1. **Read the user's description carefully.** Extract the goal, the constraints, and any
   references to existing code, diagrams, or specifications.

2. **Explore the codebase.** Read the files the user referenced. Then fan out: find
   related files, callers, tests, types, and configuration. You need enough context to
   write step files that an implementor can follow without exploring the codebase
   themselves.

   Specifically, gather:
   - The existing code that will be modified or extended
   - The test files for that code
   - The type signatures, interfaces, or protocols involved
   - The callers / consumers of the code being changed
   - Any feature flags, configuration, or environment-specific setup
   - Naming conventions and patterns used in the surrounding code

3. **Clarify ambiguities.** Do not guess. Do not proceed to Phase 2 until ambiguities
   are resolved. See Phase 1b below for the detailed Q&A process.

### Phase 1b: Resolve ambiguity through Q&A

The most important thing this skill does is ensure the plan has no gaps — no assumptions
the human made that the plan leaves implicit, and no assumptions in the plan the human
hasn't explicitly agreed to. This requires at least one round of Q&A before you begin
decomposing the work.

#### How the Q&A works

After exploring the codebase (Phase 1 step 2), compile a list of every ambiguity,
unstated assumption, and open design question. Then present them to the user in a single,
organized message. Group related questions together under headings.

**Format each question with numbered options whenever possible.** For example:

> **Data storage**
>
> 1. Where should session tokens live?
>    1. In a signed cookie (simple, no server state)
>    2. In a database-backed session store (more control, more infrastructure)
>    3. In Redis (fast, ephemeral, requires a Redis dependency)

**When options involve real trade-offs** — different technologies, competing values,
non-obvious consequences — include a brief pros/cons note for each:

> **Background job framework**
>
> The import step needs to run asynchronously. A few options:
>
> 1. **Sidekiq**
>    - Pros: Battle-tested, rich ecosystem, retries built in
>    - Cons: Requires Redis, adds an operational dependency
> 2. **GoodJob (Postgres-backed)**
>    - Pros: No new infrastructure — uses the existing database
>    - Cons: Less mature, slightly higher DB load under heavy usage
> 3. **Inline (no job framework)**
>    - Pros: No dependencies, simplest implementation
>    - Cons: Blocks the request, not viable for large imports

**When an option is straightforward** — obvious, one-line, no meaningful trade-off — a
simple numbered list without pros/cons is fine. Do not pad simple choices with unnecessary
analysis.

#### Rounds

- **Minimum: 1 round.** Always ask at least one round of clarifying questions, even if
  the request seems clear. There are always implicit assumptions worth surfacing.

- **Maximum: 2–3 rounds.** After the user answers, you may have follow-up questions
  based on their answers. That's fine — ask them. But do not stretch beyond three rounds.
  By round three, all major ambiguities should be settled.

- **If ambiguity persists after 2–3 rounds**, the problem is not more questions — it is
  that the human may not yet have a clear picture of the problem space. In that case,
  shift from asking questions to **explaining the problem**:
  - Summarize what you've learned about the codebase and the constraints.
  - Describe the two or three most likely approaches, with concrete trade-offs.
  - Identify which decision is the crux — the one choice that determines everything else.
  - Ask the user to pick a direction on that single crux decision, rather than answering
    a long list of open questions.

  This reframes the conversation from "answer my questions" to "here is what I see — does
  this match your understanding?" It makes it easier for the human to collaborate with you
  on resolving the remaining ambiguity.

#### What counts as an ambiguity

- A requirement the user mentioned vaguely ("make it fast", "handle errors properly")
- A design decision with multiple reasonable options and no stated preference
- An interaction between the new code and existing code that could go several ways
- A scope boundary — something the user might expect but didn't explicitly ask for
- An assumption you are making about the environment, dependencies, or conventions
- A constraint the user may not have considered (performance, backwards compatibility,
  migration path)

#### When to skip Q&A

Never. Even a seemingly clear request has implicit assumptions worth surfacing. If the
request really is unambiguous, the first round will be short — a few confirmations rather
than deep questions. That's fine. The round still happens.

### Phase 2: Design the decomposition

Break the change into steps. Each step should:

- **Target ~50–100 lines of diff.** This is a guideline, not a hard rule. A step that is
  purely a new file may be slightly larger. A step that is a surgical edit to an existing
  file may be smaller. The goal is that each step is easy to review in one sitting.

- **Result in a single commit.** One step = one commit. The commit should leave the
  codebase in a valid state (tests pass, no broken references).

- **Include its own tests.** Every step that adds or changes behaviour must include unit
  tests for that behaviour in the same step. Tests are not a separate step — they ship
  with the code they cover.

- **Follow a functional-core / imperative-shell shape.** Pure logic (decisions, transforms,
  calculations) lives in the functional core — small, testable, dependency-free units.
  Side effects (I/O, cookies, HTTP, database) live in a thin imperative shell that calls
  the core. When designing steps, prefer to introduce the core logic first (easy to test),
  then wire it into the shell in a later step.

- **Follow shameless green / flocking rules.** The first step that introduces a new
  concept should do the simplest thing that works — no premature abstractions. Later steps
  can refine. If two pieces of code look similar, that's fine; a future step can extract
  the duplication once the pattern is clear.

- **Have clear dependencies.** Each step declares which prior steps it depends on (or
  "None"). Independent steps can be implemented in parallel.

### Phase 3: Write the plan files

Produce exactly two things:

1. **`PLAN.md`** — the top-level plan document (in the project root)
2. **`PLAN/NN_short_name.md`** — one file per step (in a `PLAN/` directory)

#### `PLAN.md` format

```markdown
# PLAN: <title>

## Goal

<2–4 sentences: what the change accomplishes and why it matters.>

## Decision flowchart

<A mermaid flowchart showing the high-level logic of the feature being built.
This replaces any external diagrams the user may have provided. If the feature
does not have meaningful branching logic, replace this section with a brief
architecture or data-flow description instead.>

## Scope

All changes are in <zone / directory / package>.

| File | Purpose |
|------|---------|
| `path/to/file` | Brief description of what changes |
| ... | ... |

## Steps

| # | File | Description |
|---|------|-------------|
| 0 | `PLAN/00_short_name.md` | One-line description |
| 1 | `PLAN/01_short_name.md` | One-line description |
| ... | ... | ... |

## Invariants

<Bullet list of things that must remain true throughout the change. These are
the safety rails — if any step violates an invariant, something is wrong.>
```

#### Step file format (`PLAN/NN_short_name.md`)

```markdown
# Step N: <title>

## Goal

<1–2 sentences: what this step accomplishes.>

## Background

<Context the implementor needs. Reference specific files and line numbers in the
existing codebase. Explain the pattern being followed if this step mirrors an
existing one. Quote or paraphrase relevant type signatures.>

## Files to create

<For each new file: full path, and the complete intended content as a fenced code
block. If the file is long, provide the full structure with key methods filled in
and clear `# TODO` comments for anything mechanical.>

## Files to edit

<For each existing file: the full path, what to change, and a code block showing
the new or replacement code. Show enough surrounding context that the implementor
can locate the edit site unambiguously.>

## Tests

<Describe the test cases this step must include. For each test:
- The test name / description
- The setup (what state or mocks are needed)
- The assertion (what the test checks)

If this step modifies an existing test file, say so and describe both the new
tests and any changes to existing tests.

Tests must assert real behaviour — not tautologies. A test that only checks
"it doesn't crash" or "returns something truthy" is not sufficient. Tests should
verify specific return values, state changes, or side effects.>

## Acceptance criteria

<Bullet list of concrete, verifiable statements. The reviewer will check each one.>

## Dependencies

<Which prior steps must be complete before this one can start, or "None".
If there are dependencies, briefly state what they provide.>
```

### Phase 4: Review your own plan

Before presenting the plan to the user, check:

1. **Completeness.** Walk through the user's original request point by point. Is every
   requirement covered by at least one step?

2. **Step size.** Estimate the diff size for each step. If a step looks like it will
   exceed ~100 lines, split it. If a step is trivially small (~10 lines), consider
   merging it with an adjacent step.

3. **Test coverage.** Every step that changes behaviour includes tests. No step defers
   its tests to a later step (unless the step is pure refactoring with no behaviour
   change, in which case existing tests suffice).

4. **Dependencies.** Draw the dependency graph mentally. Verify there are no cycles.
   Verify that independent steps are actually independent.

5. **Mermaid diagrams.** Verify the mermaid flowchart in `PLAN.md` is accurate. If any
   step file would benefit from its own diagram (e.g., a complex branching method), add
   one.

6. **No external references.** The plan must be self-contained. Do not reference external
   diagrams, URLs, or files that won't be checked in. If the user provided a diagram,
   reproduce its content as a mermaid diagram in the plan.

## Design principles

These principles guide how you decompose a change. Include them mentally when designing
steps, but do not copy them into the plan files.

### Functional core / imperative shell

Separate pure logic from side effects. The functional core is easy to test because it
takes inputs and returns outputs with no dependencies on the environment. The imperative
shell orchestrates I/O and calls the core.

When planning steps, introduce the core first:
- Step N: Add the pure-logic class/method with unit tests
- Step N+1: Wire it into the controller/helper/shell that calls it

### Shameless green

The first implementation of a concept should be the simplest thing that makes the tests
pass. Do not introduce abstractions, configuration, or generality that isn't needed yet.
If two methods look similar, that's fine — extract later.

### Flocking rules

When you see duplication emerging across steps, note it but don't extract it until the
pattern has appeared at least twice and the extraction is obvious. A plan step that says
"refactor X and Y into a shared method" is fine as a later step, but only after both X
and Y exist.

### No tautological tests

A test must assert something that could meaningfully fail. Bad: `assert result` (truthy
check). Good: `assert_equal "expected-uuid", result` (specific value). Bad:
`assert_nothing_raised { call_method }` (no-crash check). Good:
`assert_nil result` when nil is the expected outcome for a specific input.

Tests should cover:
- The happy path with a specific expected output
- At least one edge case (nil input, empty collection, missing permission, etc.)
- Error/failure paths where the code has explicit error handling

### Commit hygiene

Each step produces one commit. The commit should:
- Leave the test suite green
- Not break any existing functionality
- Have a clear, descriptive message
- Touch only the files specified in the step

## Compatibility

The plan files produced by this skill are compatible with the `plan-orchestrator`,
`plan-implementor`, and `plan-reviewer` skills. The orchestrator reads `PLAN.md` for the
step index and dependency graph; the implementor reads individual step files for
specifications; the reviewer checks the implementation against the step's acceptance
criteria.
