# Plan: Migrate Dotfiles to Nix + Home-Manager

## Purpose of This Document

This document provides all the context a future agent needs to implement
the migration of this dotfiles repository to Nix with home-manager and
flakes. Read this entire document before starting any work.

The migration is **incremental by design**: one file or one tool at a time.
The environment must remain fully usable throughout. The old `install.sh`
system continues to work for any file not yet migrated.

A future agent reading this should: (1) read this document, (2) read the
inventory in `inventory.md`, (3) pick exactly one phase or one file from
the ordered migration steps, plan it in detail, and implement it. Do not
attempt to migrate multiple phases at once.

---

## Repository Overview

**Location**: `~/dotfiles/` (must be at `$HOME/dotfiles/` for install.sh)

**Current install mechanism** (`install.sh` + `lib/rc_helpers.sh`):
- `rc_install <src> <dest>` copies `rc/<src>` to `$HOME/<dest>`
- Platform detection via hostname + `uname` in `lib/helpers.sh`
- Four profiles: `home_mac`, `home_linux`, `work_mac`, `work_linux`
- Scripts: copied from `bin/` to `$HOME/bin/`
- LazyVim: `lazyvim/` is copied to `~/.config/nvim/`

**Current dependency mechanism** (`dependencies-install.sh` + `lib/dependencies_helpers.sh`):
- macOS: Homebrew packages (bat, fish, graphviz, node, nvim, pandoc,
  podman, rg, shellcheck, tmux, tree, uv, watch) + git-delta via cargo
- Linux: APT packages (bat, docker.io, fish, graphviz, pandoc, ripgrep,
  tmux, tree, watch) + git-delta via cargo
- Runtime versions: ASDF (nodejs, python, ruby 3.4.3)
- Rust toolchain via rustup
- Java: Amazon Corretto 11 (Linux) or Liberica JDK 21 (macOS)

**Existing Nix work** (do not discard):
- `flake.nix`: Packages the `manners` Ruby script as a Nix derivation using
  bundlerEnv. Uses nixpkgs 25.05 and flake-utils. This is the starting point.
- `gemset.nix` / `Gemfile` / `Gemfile.lock`: Ruby gem lockfiles for bundlerEnv
- `bin/note-backup`: Already uses a `nix-shell` shebang for its own deps
- `proj/nix/SPEC.md`: High-level architecture vision (worth reading)
- `proj/nix/PUNCHLIST.md`: Earlier task list (partially superseded by this plan)

---

## Target Architecture

```
flake.nix                        # Main entrypoint - expanded from current
nix/
  profiles/
    home-mac.nix                 # Home macOS home-manager config
    work-mac.nix                 # Work macOS home-manager config
    home-linux.nix               # Home Linux home-manager config
    work-linux.nix               # Work Linux home-manager config
  modules/
    shell/
      fish.nix                   # Fish shell config
      zsh.nix                    # Zsh config
      bash.nix                   # Bash config
    tools/
      git.nix                    # Git + delta config
      tmux.nix                   # Tmux config
      neovim.nix                 # Neovim/LazyVim config
      jj.nix                     # Jujutsu config
      ghostty.nix                # Ghostty terminal config
    packages/
      default.nix                # All common packages
      darwin.nix                 # macOS-only packages
      linux.nix                  # Linux-only packages
    scripts.nix                  # bin/ scripts as Nix packages
rc/                              # PRESERVED during migration - old system still works
bin/                             # PRESERVED - scripts still usable directly
install.sh                       # PRESERVED until final cleanup phase
```

The `flake.nix` will gain `home-manager` as an input and export
`homeConfigurations` for each profile. Each profile is a complete
home-manager configuration for one machine type.

---

## Core Migration Principles

### 1. Incremental file-by-file transfer

Migrate one file (or one logical group) at a time. After each migration:
- The file is placed by home-manager (symlink into `~`)
- The same file still exists in `rc/` (source of truth does not move)
- `install.sh` should be updated to skip any file managed by home-manager,
  OR you can leave it as-is since `cp` over a symlink just replaces the
  symlink with a copy (same content, still works)

### 2. Use `home.file.source` before `programs.*` DSL

The cheapest first step for any config file is:
```nix
home.file.".gitconfig".source = ./rc/gitconfig/home;
```
This gives home-manager control of file placement without touching content.
Converting content to Nix DSL (e.g., `programs.git.aliases = {...}`) is a
**separate, optional follow-up step** and should not block migration.

### 3. Never break the existing environment

- Do not delete files from `rc/` during migration
- Do not remove `install.sh` until Phase 12 (final cleanup)
- New flake outputs must not break existing `nix build` / `nix develop`
- If a home-manager activation fails, `install.sh` must still work as fallback

### 4. Profile-per-machine, modules-per-tool

Each machine profile (`home-mac.nix`, etc.) imports the relevant modules.
Platform differences live in the modules via `pkgs.stdenv.isDarwin` or via
separate darwin/linux module files imported by the profile.

### 5. Commit after each file migrated

Each file migration should be a separate git commit. This makes rollback
trivial and keeps history readable.

---

## Migration Order

The phases below are ordered by: (1) foundational dependencies first,
(2) lowest risk first, (3) highest daily-use value first. **Do not skip
phases.** Each phase depends on the previous being stable.

### Phase 0: Bootstrap (FIRST - blocks everything else)

Add `home-manager` to `flake.nix` and create the skeletal profile/module
structure. No files are migrated yet. This sets up the scaffolding.

See `phase-0-bootstrap.md` for detailed steps.

### Phase 1: Simple static dotfiles

Low-risk, small files with no dependencies. Good for learning the pattern
before tackling complex configs.

Files (in order):
1. `rc/rg/ignore` → `~/.ignore`
2. `rc/sh/inputrc` → `~/.inputrc`
3. `rc/gitconfig/gitignore` → `~/.gitignore`
4. `rc/aspell/dictionary.txt` → `~/var/dictionary.txt`

### Phase 2: Git configuration

High value, well-supported by `programs.git` in home-manager.
Start with `home.file.source` approach, then optionally convert to DSL.

Files (per profile):
- `rc/gitconfig/home` → `~/.gitconfig` (home-mac, home-linux)
- `rc/gitconfig/work` → `~/.gitconfig` (work-mac, work-linux)
- `rc/gitconfig/work-dev` → `~/.config/dev/gitconfig` (work-mac only)

### Phase 3: Fish shell configuration

Fish is the primary shell. Start with base config, then add platform
variants. Use `programs.fish.extraConfig` or `home.file.source`.

Files (in order):
1. `rc/fish/config` → `~/.config/fish/config.fish` (all profiles)
2. `rc/fish/mac_config` → `~/.config/fish/conf.d/500_mac_config.fish`
3. `rc/fish/linux_config` → `~/.config/fish/conf.d/500_linux_config.fish`
4. `rc/fish/home_mac_config` → `~/.config/fish/conf.d/550_home_mac_config.fish`
5. `rc/fish/work_mac_config` → `~/.config/fish/conf.d/550_work_mac_config.fish`
6. `rc/fish/dev_config` → `~/.config/fish/conf.d/700_dev_config.fish` (work-mac)
7. `rc/asdf/fish_config` → `~/.config/fish/conf.d/600_asdf_config.fish`

Note: The asdf fish_config sources `(brew --prefix asdf)/libexec/asdf.fish`.
During this phase, keep that as-is. ASDF replacement happens in Phase 9.

### Phase 4: Ghostty terminal

Single config file, no dependencies.

File: `rc/ghostty/config` → `~/.config/ghostty/config`

### Phase 5: Tmux

The `tmux/conf` is a copy of gpakosz/.tmux (noted as "do not edit this
file"). Manage it as an opaque file via `home.file.source`. The local
overrides file `tmux/conf_local` is where actual customizations live.

Files:
1. `rc/tmux/conf` → `~/.tmux.conf`
2. `rc/tmux/conf_local` → `~/.tmux.conf.local`

### Phase 6: JJ (Jujutsu)

VCS config. Has home and work variants like gitconfig.

Files:
- `rc/jj/home_config` → `~/.config/jj/config.toml` (home profiles)
- `rc/jj/work_config` → `~/.config/jj/config.toml` (work profiles)

### Phase 7: Bash and Zsh

Secondary shells, used as fallback. Lower priority than fish.

Files:
- `rc/bash/bash_profile` → `~/.bash_profile` (all profiles)
- `rc/sh/profile` → `~/.profile` (all profiles)
- `rc/zsh/mac_zshrc` → `~/.zshrc` (home-mac, work-mac)
- `rc/zsh/work_zshrc` → `~/.zshrc` (work-mac, overrides mac_zshrc)

Note: install.sh installs `work_zshrc` for work-mac, not mac_zshrc.
The work profile should use `work_zshrc`.

### Phase 8: Neovim / LazyVim

More complex because it's a directory (not a single file).

Strategy: Use `home.file` with multiple source mappings, or use
`xdg.configFile` to map `lazyvim/` → `~/.config/nvim/`.

```nix
xdg.configFile."nvim" = {
  source = ./lazyvim;
  recursive = true;
};
```

Also manage `rc/vim/vimrc` → `~/.vimrc` and `rc/vim/nvimrc` as needed.

Do NOT convert LazyVim lua to Nix DSL - LazyVim manages its own plugin
system and does not need Nix-level management.

### Phase 9: Package management (high impact)

Replace Homebrew/APT/ASDF with `home.packages`. This is the most impactful
phase but also the riskiest - test carefully.

**macOS packages** (via home-manager + nix-darwin if applicable, otherwise
home-manager standalone):
```
bat, fish, graphviz, nodejs, neovim, pandoc, podman, ripgrep,
shellcheck, tmux, tree, uv, watch, git-delta
```

**Linux packages**:
```
bat, docker, fish, graphviz, pandoc, ripgrep, tmux, tree, watch,
git-delta
```

**ASDF replacement**: Use `home.packages` to install language runtimes:
- ruby: `pkgs.ruby_3_4` or `pkgs.ruby`
- nodejs: `pkgs.nodejs`
- python: `pkgs.python3`

Remove `rc/asdf/fish_config` from fish conf.d once ASDF is no longer needed.

**Rust**: Use `pkgs.rustup` or `pkgs.cargo` in home.packages.
Remove the rustup-based install in dependencies_helpers.sh references.

**Java**: Use `pkgs.corretto11` (Amazon Corretto 11) or `pkgs.temurin-bin-21`.

Note: Some packages (podman, docker, Java) may require system-level config
beyond home-manager scope. Flag these for manual follow-up.

### Phase 10: Scripts (bin/)

Extend the existing `flake.nix` derivation to wrap all Ruby scripts, not
just `manners`. The current flake already has the `wrapScript` helper and
`bundlerEnv` setup.

All scripts in `bin/` except:
- `setup-claude-mcp.sh` / `remove-claude-mcp.sh` (bash, no Ruby deps)
- `pandoc-pdf` (bash, needs pandoc in PATH)
- `slack-paste` (osascript, macOS-only)
- `note-backup` (already uses nix-shell shebang)

Scripts with hardcoded ASDF shebang paths (`#!/Users/millerhall/.asdf/...`)
need their shebangs changed to `#!/usr/bin/env ruby` before or during this
phase.

Use home-manager's `home.packages` to install the flake's scripts package:
```nix
home.packages = [ self.packages.${pkgs.system}.default ];
```

### Phase 11: Shell environment variables and PATH cleanup

After Phase 9+10, clean up PATH management in fish/zsh/bash configs:
- Remove `$HOME/.cargo/bin` path additions (if Rust is managed by Nix)
- Remove ASDF-related path additions
- Remove Homebrew path additions (if packages are managed by Nix)
- Keep `$HOME/bin` in PATH for any scripts not yet in Nix package

### Phase 12: Retire old scripts

Only after all profiles are tested and stable on all machine types:
- Archive `install.sh` and `dependencies-install.sh` (keep in git history)
- Update `README.md` with new setup instructions
- Update `lib/` helpers (can be kept for reference)
- Consider removing `proj/nix/PUNCHLIST.md` (superseded by this plan)

---

## Decision Log

### Why keep `rc/` files as source of truth initially?

The `home.file.source = ./rc/...` approach means:
1. No content changes needed in early phases
2. If home-manager activation fails, the original files still exist in `rc/`
3. The diff between "before migration" and "after migration" for a given file
   is purely structural (who manages placement), not content
4. Content-to-DSL conversion can happen independently as a refactor

### Why not use nix-darwin?

nix-darwin manages system-level macOS configuration (fonts, system defaults,
services). That's out of scope for this migration, which focuses on user-level
dotfiles. Home-manager standalone works on both macOS and Linux without
requiring system-level Nix installation.

### Why keep LazyVim as a directory, not convert to Nix?

LazyVim has its own plugin manager (lazy.nvim) and lockfile (`lazy-lock.json`).
Converting it to Nixvim or managing plugins via Nix would be a major separate
project. The pragmatic approach is to let LazyVim manage itself and just have
home-manager place the files.

### Why is Phase 9 (packages) not the first phase?

Package management is the highest-risk migration. Changing from Homebrew to
Nix packages can break tools in subtle ways (PATH ordering, linked libraries,
etc.). Migrating config files first means the environment stays stable, and
package migration can be tested incrementally after the lower-risk work.

### Profile detection strategy

The old system uses hostname matching. Home-manager profiles are selected at
activation time. The user runs `home-manager switch --flake .#profile-name`
explicitly. No automatic hostname detection needed in home-manager itself.

However, a convenience script in `bin/` or a `Makefile` target could detect
the hostname and invoke the right profile, matching the old behavior.

### ASDF vs Nix for runtime management

ASDF and Nix can coexist during the transition. In fish config, the ASDF
source line (`source (brew --prefix asdf)/libexec/asdf.fish`) can stay active
until Phase 9 is complete and tested. Once Nix manages runtimes, the ASDF
config fish file is simply removed from conf.d.

---

## Testing a Phase

After implementing any phase, verify:
1. `nix flake check` passes
2. `home-manager switch --flake .#<profile>` activates without errors
3. The migrated file is present at the expected destination
4. The file content is correct (diff against `rc/` source if using
   `home.file.source`)
5. The old `install.sh` still runs without error (optional, belt-and-suspenders)
6. Any tool that uses the migrated config file still works (e.g., after
   migrating gitconfig, run `git log` and verify aliases work)

---

## Known Complications

### work-mac gitconfig includes external path

`rc/gitconfig/work` has `[include] path = /Users/millerhall/.config/dev/gitconfig`.
This is a Shopify `dev` tool path. Leave this include in place; do not try to
manage that external file via home-manager.

### bin/ scripts have hardcoded ASDF paths

Most scripts in `bin/` start with:
```
#!/Users/millerhall/.asdf/installs/ruby/3.4.3/bin/ruby
```
These break if ruby is not installed at that exact path. The current `flake.nix`
already handles this for `manners` via `wrapProgram`. The same pattern needs
to apply to all other scripts in Phase 10.

Before Phase 10: these scripts only work with ASDF-installed Ruby.
After Phase 10: Nix wraps them with the right Ruby in PATH.

### note-backup already uses nix-shell shebang

`bin/note-backup` starts with:
```
#!/usr/bin/env nix-shell
#! nix-shell -I nixpkgs=channel:nixos-25.05 -p "ruby.withPackages (...)" -i ruby
```
This is a valid Nix approach. When migrating scripts in Phase 10, this script
can be left as-is (nix-shell inline) or converted to use the bundlerEnv, whichever
is simpler.

### tec agent init in fish config

`rc/fish/config` ends with:
```fish
test -x /Users/millerhall/.local/state/tec/profiles/base/current/global/init && \
  /Users/millerhall/.local/state/tec/profiles/base/current/global/init fish | source
```
This is a Shopify `tec` tool. It's work-specific. Move this line to
`rc/fish/work_mac_config` if it isn't already, or guard it with `if is_mac`
and `if hostname | grep work` equivalent in Nix.

During Phase 3 migration, just copy the file as-is. The conditional in the
script handles the case where `tec` is not installed.

### ghostty config has macOS-only command path

`rc/ghostty/config` has `command = /opt/homebrew/bin/fish`. After Phase 9
(package migration), this path will change to the Nix store. Update this
file to use `command = fish` (relies on PATH) or make it profile-specific.

---

## Quick Reference: File Inventory

See `inventory.md` for the complete, annotated list of every file that
needs to be migrated, with its source path, destination path, and profile
applicability.
