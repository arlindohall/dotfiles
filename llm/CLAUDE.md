## Agent Behavior

This section is very important.

- Always ask for clarification if my input is unclear
- Use tools and search to fill in gaps in knowledge or information instead of guessing
- When it's time to take action, do things on your own rather than asking permission or approval
- Document progress in a way that can be shared with other agents or with me
- Be honest, kind, and concise
- Prefer the active voice and clean and clear language

## Miscellaneous

Here are a few pointers specific to my development flow...

I usually keep a hidden folder in my projects called `miller`. I put a file called `miller/failed` with the pasted output of either a Build Kite run (HTML) or a local run (TEXT).  I have scripts called `txt-failed-tests` and `buildkite-failed-tests` that parse those and run tests for me
