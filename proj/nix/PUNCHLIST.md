# Nix Migration Punchlist

## Foundation Setup

- [ ] Install Nix with flakes support
- [ ] Install Home Manager
- [ ] Create basic `flake.nix` with inputs (nixpkgs, home-manager)
- [ ] Create `flake.lock` with pinned versions

## Core Infrastructure  

- [ ] Create basic Home Manager configuration structure
- [ ] Set up host-specific configurations (`hosts/home-mac.nix`, `hosts/work-mac.nix`, `hosts/linux.nix`)
- [ ] Create modular configuration system (`modules/` directory)
- [ ] Configure flake outputs for each host configuration

## Shell Environment Migration

- [ ] Migrate Fish shell configuration to Home Manager
- [ ] Port Fish platform-specific configs (mac_config, linux_config, etc.)
- [ ] Migrate Bash configuration (.bash_profile, .profile)
- [ ] Port Zsh configurations (mac_zshrc, work_zshrc)
- [ ] Configure shell aliases and environment variables in Nix

## Development Tools

- [ ] Replace ASDF with Nix-managed runtimes
- [ ] Configure Ruby 3.4.3 environment
- [ ] Set up Git configuration via Home Manager
- [ ] Install and configure Git Delta via Nix
- [ ] Replace Rust installation with Nix-managed Rust toolchain

## Editor Configuration

- [ ] Migrate Vim/Neovim configuration to Home Manager
- [ ] Port LazyVim setup to work with Nix-managed Neovim
- [ ] Configure Neovim plugins through Nix when possible
- [ ] Set up editor-specific environment variables

## Terminal and Multiplexer

- [ ] Migrate tmux configuration to Home Manager
- [ ] Port tmux.conf and tmux.conf.local settings
- [ ] Configure terminal-specific settings

## Package Management Migration

### macOS Packages
- [ ] Inventory current Homebrew packages
- [ ] Find Nix equivalents for Homebrew packages
- [ ] Replace `install_homebrew_tools` with Nix packages
- [ ] Handle macOS-specific packages (casks, etc.)

### Linux Packages  
- [ ] Inventory current APT packages
- [ ] Find Nix equivalents for APT packages
- [ ] Replace `install_apt_tools` with Nix packages

### Universal Tools
- [ ] Install aider via Nix
- [ ] Install clang via Nix
- [ ] Install OpenJDK via Nix

## Personal Scripts Package

- [ ] Create Nix derivation for `bin/` directory scripts
- [ ] Handle Ruby script dependencies (add Ruby to buildInputs)
- [ ] Configure proper shebangs and PATH for scripts
- [ ] Test all personal scripts work in Nix environment
- [ ] Package scripts for easy installation across machines

## Configuration Files

- [ ] Migrate aspell dictionary configuration
- [ ] Port gitconfig variations (home, work, work-dev)
- [ ] Set up gitignore through Home Manager
- [ ] Configure inputrc via Home Manager
- [ ] Handle jujutsu (jj) configurations

## Platform-Specific Configurations

### Home Mac
- [ ] Configure home-mac specific packages and settings
- [ ] Handle personal repository cloning (notes repo)
- [ ] Set up home-specific Fish configuration

### Work Mac  
- [ ] Configure work-mac specific packages and settings
- [ ] Handle work-specific development tools
- [ ] Set up work-specific Fish and Git configurations
- [ ] Configure work-dev specific gitconfig

### Linux
- [ ] Configure Linux-specific packages and settings
- [ ] Handle Linux-specific Fish configuration
- [ ] Test on both Ubuntu and other distros if needed

## Testing and Validation

- [ ] Test flake builds successfully (`nix flake check`)
- [ ] Test home-mac configuration activation
- [ ] Test work-mac configuration activation  
- [ ] Test linux configuration activation
- [ ] Verify all dotfiles are correctly placed
- [ ] Verify all packages are available and functional
- [ ] Test personal scripts work correctly
- [ ] Verify development environments work (Ruby, etc.)

## Migration and Cleanup

- [ ] Create migration script to backup existing dotfiles
- [ ] Test Nix configuration alongside existing setup
- [ ] Switch to Nix-managed configurations
- [ ] Archive old shell scripts (`install.sh`, `dependencies-install.sh`)
- [ ] Update README with Nix installation instructions
- [ ] Document new workflow for managing configurations

## Documentation

- [ ] Write Nix-specific setup instructions
- [ ] Document how to add new packages
- [ ] Document how to modify configurations  
- [ ] Document platform-specific customizations
- [ ] Document development shell usage
- [ ] Create troubleshooting guide for common issues