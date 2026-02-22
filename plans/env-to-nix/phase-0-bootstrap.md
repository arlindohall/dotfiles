# Phase 0: Bootstrap - Add Home-Manager to Flake

## Goal

Set up the scaffolding for all future phases. After this phase:
- `home-manager` is an input in `flake.nix`
- Four home-manager profiles exist (home-mac, work-mac, home-linux, work-linux)
- Each profile activates without error but manages zero files
- The existing `packages.default` (Ruby scripts) still builds
- The existing `devShells.default` still works

## Prerequisites

- Nix must be installed on the machine with flakes enabled
  (`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`
  or `/etc/nix/nix.conf`)
- home-manager does NOT need to be installed as a standalone tool;
  it is invoked via `nix run home-manager/...` or via the flake

## Files to Create

```
nix/
  profiles/
    home-mac.nix
    work-mac.nix
    home-linux.nix
    work-linux.nix
  modules/            (empty dir with .gitkeep for now)
```

Update: `flake.nix`

## Step-by-Step

### 1. Update flake.nix inputs

Add home-manager to the inputs block:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  flake-utils.url = "github:numtide/flake-utils";
  home-manager = {
    url = "github:nix-community/home-manager/release-25.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Use `release-25.05` to match nixpkgs channel. The `inputs.nixpkgs.follows`
ensures home-manager uses the same nixpkgs as the rest of the flake.

### 2. Update flake.nix outputs

Add `home-manager` to the outputs function parameters, and add
`homeConfigurations` output alongside the existing `packages` and `devShells`:

```nix
outputs =
  {
    self,
    nixpkgs,
    flake-utils,
    home-manager,
  }:
  let
    # Home configurations are per-system, defined separately
    homeConfigurations = {
      "home-mac" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./nix/profiles/home-mac.nix ];
        extraSpecialArgs = { inherit self; };
      };
      "work-mac" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./nix/profiles/work-mac.nix ];
        extraSpecialArgs = { inherit self; };
      };
      "home-linux" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./nix/profiles/home-linux.nix ];
        extraSpecialArgs = { inherit self; };
      };
      "work-linux" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./nix/profiles/work-linux.nix ];
        extraSpecialArgs = { inherit self; };
      };
    };
  in
  # Keep existing flake-utils outputs, then merge homeConfigurations
  flake-utils.lib.eachDefaultSystem ( ... ) // { inherit homeConfigurations; };
```

Note: The `//` merge appends `homeConfigurations` to the system-scoped
outputs from flake-utils. The system architectures (`aarch64-darwin`,
`x86_64-linux`) are hardcoded per profile since home configurations are
per-machine. Adjust if the actual machines use different architectures
(e.g., `x86_64-darwin` for Intel Macs).

### 3. Create minimal profile files

Each profile file is a home-manager module. Start minimal:

**`nix/profiles/home-mac.nix`**:
```nix
{ pkgs, self, ... }:

{
  home.username = "millerhall";
  home.homeDirectory = "/Users/millerhall";
  home.stateVersion = "25.05";

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
```

**`nix/profiles/work-mac.nix`**:
```nix
{ pkgs, self, ... }:

{
  home.username = "millerhall";
  home.homeDirectory = "/Users/millerhall";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
```

**`nix/profiles/home-linux.nix`**:
```nix
{ pkgs, self, ... }:

{
  home.username = "millerhall";
  home.homeDirectory = "/home/millerhall";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
```

**`nix/profiles/work-linux.nix`**:
```nix
{ pkgs, self, ... }:

{
  home.username = "millerhall";
  home.homeDirectory = "/home/millerhall";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
```

**IMPORTANT**: The `home.username` and `home.homeDirectory` values must
match the actual user. Verify these before activating. If the username
differs between machines, either use a common value or parameterize it.

**IMPORTANT**: The `home.stateVersion` should be set to the home-manager
release being used (25.05 here) and **never changed after first activation**.
It is used to preserve backwards-compatible behavior for certain options.

### 4. Create modules directory placeholder

```
mkdir -p nix/modules
touch nix/modules/.gitkeep
```

### 5. Run flake check

```
nix flake check
```

This will evaluate all flake outputs. If there are evaluation errors in
any profile, fix them before proceeding.

Note: `nix flake check` will try to build all outputs including
`homeConfigurations`. If it tries to evaluate Linux configs on macOS,
it may fail. You can check individual configs:

```
nix eval .#homeConfigurations.home-mac.config.home.username
```

### 6. Do a dry-run activation

On the target machine, test activation without writing files:

```
nix run home-manager/release-25.05 -- switch --flake .#home-mac --dry-run
```

Or if home-manager is installed:
```
home-manager switch --flake .#home-mac --dry-run
```

### 7. Activate for real (on target machine)

```
home-manager switch --flake .#home-mac
```

This should succeed and report that 0 files changed (since the profile
manages nothing yet).

## Verification

- `nix flake check` passes (or passes for the current system's outputs)
- `nix build .#packages.aarch64-darwin.default` still builds (Ruby scripts)
- `nix develop` still works
- `home-manager switch --flake .#<profile>` activates successfully
- `home-manager generations` shows a generation entry

## What NOT to do in this phase

- Do not migrate any files yet
- Do not install any packages yet
- Do not set `home.packages` or `home.file` entries yet
- Do not remove or modify any existing `rc/` files
- Do not change `install.sh`

## Notes on Architecture Choices

### System architecture per profile

The profile system architectures are hardcoded above. If you're unsure
of the architecture, run `uname -m` on the target machine:
- `arm64` → `aarch64-darwin` (Apple Silicon Mac)
- `x86_64` on macOS → `x86_64-darwin` (Intel Mac)
- `x86_64` on Linux → `x86_64-linux`
- `aarch64` on Linux → `aarch64-linux`

### Alternative: use pkgs.system

Instead of hardcoding per-profile, you could use `builtins.currentSystem`
but this makes the flake impure. The hardcoded approach is the conventional
Nix flakes pattern for home configurations.

### stateVersion

Use `25.05` for the initial setup. This aligns with the nixpkgs channel.
Never change this value after the first activation on a given machine.
