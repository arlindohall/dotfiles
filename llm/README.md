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

After making changes to files in this repo, you can install them (and everything int the repo) with:

```sh
~/dotfiles/install.sh
```

To back up your installed agent config back to this dotfiles repo. Do this before making changes to be sure nothing gets lost on `install.sh`:

```sh
cp -r ~/.pi/agent/skills/* ~/dotfiles/llm/skills/
cp -r ~/.pi/agent/plugins/* ~/dotfiles/llm/plugins/
```
