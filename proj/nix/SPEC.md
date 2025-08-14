# Dotfiles Nix Migration Specification

## Current State Analysis

Your dotfiles are currently organized as a traditional shell-based configuration management system with:

- **Configuration files**: Stored in `rc/` directory with platform-specific variants (home_mac, work_mac, linux)
- **Installation scripts**: `install.sh` for dotfiles, `dependencies-install.sh` for package management
- **Dependencies**: Managed via Homebrew (macOS), APT (Linux), ASDF for runtime versions, and Rust toolchain
- **Custom scripts**: Personal utilities in `bin/` directory
- **Runtime environments**: Ruby (3.4.3), various language tools via ASDF

## Nix Migration Vision

The target state transforms your dotfiles into a declarative Nix system that:

1. **Replaces imperative scripts** with declarative Nix configurations
2. **Unifies dependency management** across all platforms using Nix packages
3. **Provides reproducible environments** through Nix flakes
4. **Maintains your existing workflow** while gaining Nix's benefits
5. **Supports multiple machine types** (home_mac, work_mac, linux) through Nix configurations

## Architecture Changes

### From Script-Based to Declarative

**Current approach:**
- Shell scripts detect platform and install dependencies
- Manual symlink creation for dotfiles
- Platform-specific package managers (brew, apt)

**Nix approach:**
- Nix flake defines all configurations declaratively
- Home Manager handles dotfile placement automatically
- Nix packages replace all package managers

### Configuration Structure

```
flake.nix                    # Main flake entrypoint
├── hosts/
│   ├── home-mac.nix        # Home macOS configuration
│   ├── work-mac.nix        # Work macOS configuration
│   └── linux.nix           # Linux configuration
├── modules/
│   ├── shell/              # Fish, Bash, Zsh configs
│   ├── editors/            # Vim, Neovim configs
│   ├── git/                # Git configurations
│   ├── tmux/               # Terminal multiplexer
│   └── development/        # Dev tools, ASDF replacements
└── packages/
    └── personal-scripts/   # Your bin/ directory as Nix package
```

### Dependency Management Transformation

**Replace these components:**

1. **ASDF** → Nix dev shells and runtime management
2. **Homebrew/APT packages** → Nix packages
3. **Rust toolchain install** → Nix-managed Rust
4. **Manual Git/Delta install** → Nix packages
5. **Custom script copying** → Nix package derivation

### Environment Management

**Current challenges addressed:**

- **Platform differences**: Nix handles macOS/Linux variations
- **Dependency drift**: Reproducible builds prevent version mismatches  
- **Manual setup**: Single `nix run` command replaces all scripts
- **State management**: Nix's functional approach eliminates hidden state

## Integration Points

### Home Manager Integration
- Manages all dotfile placement (replaces `rc_install` functions)
- Handles service management and shell integration
- Provides declarative package installation

### Flakes as Entry Points
- `nix run .#home-mac` → Setup home macOS environment
- `nix run .#work-mac` → Setup work macOS environment  
- `nix run .#linux` → Setup Linux environment
- `nix develop` → Enter development shell with all tools

### Personal Scripts as Nix Package
Your `bin/` directory becomes a proper Nix package with:
- Proper dependency declarations for Ruby scripts
- Shell script linting and validation
- Automatic PATH management across systems

## Migration Benefits

1. **Reproducibility**: Identical environments across machines
2. **Rollbacks**: Easy reversion to previous configurations
3. **Isolation**: No more global package pollution
4. **Documentation**: Configuration serves as documentation
5. **Testing**: Validate configurations before deployment
6. **Sharing**: Easy to share and collaborate on configurations

## Compatibility Considerations

### Preserving Existing Workflow
- Fish shell configurations remain largely unchanged
- Git configurations maintain existing structure
- LazyVim setup continues working with Nix-managed Neovim
- Ruby development maintains Gemfile-based dependencies

### Platform-Specific Handling
- macOS: Darwin-specific Nix packages and configurations
- Linux: NixOS-style configurations adapted for standalone use
- Work environments: Separate configurations with appropriate tooling

### Migration Path
The migration can be incremental:
1. Start with a basic flake that reproduces current functionality
2. Gradually replace script-based installations with Nix equivalents
3. Add new features (dev shells, better isolation) once basic migration complete
4. Retire old scripts once Nix versions proven stable

This approach maintains your productive workflow while gaining Nix's powerful configuration management capabilities.