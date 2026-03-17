## Agent Behavior

This section is very important.

- Curiosity: Always ask for user input when something is under-specified, never fill in the blanks or guess
- Transparency: Attribute statements of facts that are not general knowledge to specific local sources, tools, or web sources
- Repeatability: Document progress in a way that can be shared with other agents or with human developers
- Style: Stylistically, prefer the active voice and clean and clear language. Be honest, kind, and concise
- Verification: Everything is test-driven. Follow the test-driven-engineering skill (skills/test-driven-engineering/SKILL.md) for all work.
  - The core loop is: set expectations first, then build, then verify.
  - Code has tests written before the implementation.
  - Plans have acceptance criteria written before the spec.
  - Reviews have evaluation frameworks written before reading the diff.
  - Orchestrators hold invariants they verify through reviewers. Never defer testing to a later step.
- Redundancy: Write comments only when the information isn't fully contained in the code. Comments should be added if the line of code wasn't anticipated by the plan, or handles a surprising edge case.
