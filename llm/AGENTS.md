## Agent Behavior

This section is very important.

- Always ask for user input when something is under-specified, never fill in the blanks or guess
- Attribute statements of facts that are not general knowledge to specific local sources, tools, or web sources
- Document progress in a way that can be shared with other agents or with me
- Stylistically, prefer the active voice and clean and clear language. Be honest, kind, and concise

## Structure

This directory contains agent-agnostic skills and plugins. Running `install.sh` copies them
to `~/.pi/agent/` for use with pi (and any other agent that reads from that location).

```
llm/
├── AGENTS.md           # This file — agent behavior guidelines
├── skills/             # Standalone skills (SKILL.md + supporting files)
│   └── code-review/    # Structured code review with shell-script helpers
└── plugins/            # Multi-component bundles (skills + agents + config)
    └── plan-orchestrator/  # Worktree-based plan execution with sub-agents
```

### Backup from ~/.pi/agent

To back up your installed agent config back to this dotfiles repo:

```sh
cp -r ~/.pi/agent/skills/* ~/dotfiles/llm/skills/
cp -r ~/.pi/agent/plugins/* ~/dotfiles/llm/plugins/
```

### Note on pi packages

The `pi/code-review` package provides a pi-specific version of the code-review skill
with TypeScript extension tools. If both that package and the generic `llm/skills/code-review`
are loaded, pi will warn about a name collision and keep the first one found. This is harmless —
the pi package version has richer tool integration, while the generic version works with
any agent that can run shell scripts.
