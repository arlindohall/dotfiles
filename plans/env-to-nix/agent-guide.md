# Guide for Agents Implementing This Migration

This document tells you exactly how to work on this migration. Read this
before reading `README.md`, then read `README.md`, then read `inventory.md`,
then pick the next incomplete phase.

---

## Your job in each session

You are one agent in a series. Each agent session should:

1. Read `README.md`, `inventory.md`, and this file
2. Check git log to see what has already been done
3. Identify the **next incomplete phase** (or the next file within a phase)
4. Make a detailed implementation plan for just that one phase/file
5. Implement it
6. Test it (see verification steps in each phase doc)
7. Commit with a clear message
8. Push to the feature branch

**Never implement more than one phase per session** unless a phase is trivially
small (e.g., a single-line file). The goal is systematic, reviewable progress.

---

## How to check current migration status

```bash
# See what nix/ directory contains
ls nix/ 2>/dev/null || echo "Phase 0 not yet done"

# See recent commits
git log --oneline -20

# Check which profiles exist
ls nix/profiles/ 2>/dev/null

# Check which modules exist
ls nix/modules/ 2>/dev/null

# Check if home-manager is in the flake
grep home-manager flake.nix
```

If `nix/` does not exist or `flake.nix` has no `home-manager` input,
**Phase 0 has not been done**. Do Phase 0 first.

---

## The migration pattern for a single file

Every config file migration follows the same pattern:

### Step 1: Add `home.file` entry to the profile

In the relevant profile file(s) in `nix/profiles/`, add:

```nix
home.file."<destination-relative-to-home>" = {
  source = ../../rc/<source-path>;
};
```

Example (migrating rg/ignore):
```nix
home.file.".ignore" = {
  source = ../../rc/rg/ignore;
};
```

### Step 2: Test with dry-run

```bash
home-manager switch --flake .#<profile> --dry-run
```

Check that the dry-run shows the expected file will be created/linked.

### Step 3: Activate

```bash
home-manager switch --flake .#<profile>
```

### Step 4: Verify

- The destination file exists at `~/<destination>`
- It's a symlink pointing into the Nix store (home-manager default)
- The content matches `rc/<source>`:
  ```bash
  diff ~/.<destination> rc/<source>
  ```

### Step 5: Remove from install.sh

Find the `rc_install` call in `install.sh` that places this file and
either:
- Delete the line (if you're confident this profile is stable), OR
- Comment it out with a note: `# Migrated to home-manager`

Do this only for the profiles that have been updated. Keep `rc_install`
for other profiles until those profiles are also migrated.

### Step 6: Commit

```bash
git add nix/profiles/<profile>.nix install.sh
git commit -m "nix: manage <destination> via home-manager in <profile>"
```

---

## Handling per-profile differences

Some files have different variants per profile (e.g., gitconfig/home vs
gitconfig/work). The module system is the right place to handle this:

**Option A: Inline conditionals in profile file**

In `nix/profiles/home-mac.nix`:
```nix
home.file.".gitconfig".source = ../../rc/gitconfig/home;
```

In `nix/profiles/work-mac.nix`:
```nix
home.file.".gitconfig".source = ../../rc/gitconfig/work;
```

This is the simplest approach.

**Option B: Module with a parameter**

Create `nix/modules/git.nix`:
```nix
{ gitconfigVariant, ... }:

{
  home.file.".gitconfig".source = ../../rc/gitconfig/${gitconfigVariant};
}
```

Then in each profile:
```nix
imports = [ (import ../modules/git.nix { gitconfigVariant = "home"; }) ];
```

Option A is preferred for early phases. Use Option B once multiple files
share the same parameterization pattern.

---

## Module extraction

Once 3+ profiles share the same `home.file` entry, extract it to a module.

Pattern:
```nix
# nix/modules/rg.nix
{ ... }:
{
  home.file.".ignore".source = ../../rc/rg/ignore;
}
```

Then in each profile:
```nix
imports = [
  ../modules/rg.nix
  # ...
];
```

Do not extract too early. Wait until you have real duplication.

---

## Testing tips

### nix flake check

Run before and after every change:
```bash
nix flake check
```

If it fails on foreign-architecture home configs (e.g., evaluating Linux
configs on Mac), that's acceptable - only test the configs for your
current machine.

### Test without activating

To evaluate the config without activating:
```bash
nix eval .#homeConfigurations.home-mac.config.home.file
```

This shows what files home-manager would manage.

### Checking what home-manager manages

After activation:
```bash
home-manager packages    # managed packages
home-manager news        # pending news items
```

View managed files:
```bash
ls -la ~/.config/home-manager/
```

---

## Common pitfalls

### home.file paths are relative to home, not absolute

```nix
# CORRECT
home.file.".gitconfig".source = ...;
home.file.".config/fish/config.fish".source = ...;

# WRONG - don't include leading /
home.file."/.gitconfig".source = ...;
```

### Source paths in Nix must be within the flake

All `source = ...` paths must be within the git-tracked repository.
Using paths outside the repo (like `~/.config/...`) will not work.

### home-manager makes symlinks, not copies

Home-manager places symlinks by default. If something expects a writable
file (not a symlink), you may need:
```nix
home.file."path" = {
  source = ./rc/path;
  # or use:
  text = builtins.readFile ./rc/path;
};
```

Most dotfiles are fine as symlinks. LazyVim's `lazy-lock.json` is written
by the app itself - this may require special handling (see Phase 8).

### Activation fails on files that already exist as regular files

If home-manager tries to place a symlink where a regular file exists,
it will fail. Solution:
```bash
rm ~/.gitconfig  # or mv ~/.gitconfig ~/.gitconfig.bak
home-manager switch --flake .#<profile>
```

The old `install.sh` places copies (not symlinks), so this situation
will arise for every file. Back up and remove the old copy before
home-manager activation.

### Using `recursive = true` for directories

When managing a directory (like LazyVim):
```nix
xdg.configFile."nvim" = {
  source = ./lazyvim;
  recursive = true;
};
```

This places symlinks for each file in the directory. If the app writes
to files in this directory (like `lazy-lock.json`), those writes will
fail on symlinks. Use `mutableFile = true` or manage the directory
differently for writable files.

---

## Commit message convention

Use this format:
```
nix: <action> <what> [in <profile>]
```

Examples:
```
nix: bootstrap home-manager with four empty profiles
nix: manage .ignore via home-manager in all profiles
nix: manage .gitconfig via home-manager in home profiles
nix: extract git module from profiles
nix: add common packages to all profiles
```

---

## Branch and push

Always work on the branch specified in the task. After completing a phase:

```bash
git push -u origin <branch-name>
```

The branch should be `claude/plan-nix-migration-FWBNI` or whatever is
specified in the current task context.
