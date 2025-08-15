## Execution plans

- When I start up Claude, I may or may not have an execution plan
- I usually refer to this as a "punch list" or "punchlist" or "execution plan"
- If I am using a punch list, it will be located in my project at `proj/<some-project-name>/PUNCHLIST.md`
- The punch list will be a markdown document formatted GitHub style
- The main content is a punch list bulleted with `- [ ]` or `- [x]`
- The whole punch list is bulleted except for (optional) headers to group bullets

If I ask to generate an execution plan, I'm looking for a punch list and a spec.

- I will provide some context as to what's going on
- Write up a description of the current and desired states in a file called `proj/<some-project-name>/SPEC.md`
- Write up a punch list of the tasks needed to reach the desired state in a file called `proj/<some-project-name>/PUNCHLIST.md`
- The SPEC is sufficiently detailed for a new junior developer to read and understand the necessary work
- The PUNCHLIST is sufficiently detailed and simple for a new junior developer to follow without intervention

### Example execution plan

The following example is simplified. The real spec and punch list should be as brief, succinct, and clear as
possible, but should not be overly simplistic and should use an expert software developer's level of knowledge and
details to break the task down. The examples given show the structure, but not the ideal level of depth or length.

Section titles in the SPEC should be customized to match the needs of the specific project. Section titles in the
PUNCHLIST should group related tasks together, if necessary, or if not then there should only be list items.

More, or fewer, or different sections should be used if appropriate.

<template-execution-plan>

<metadata desc="specific values that should be replaced">
  <project-name>Dropdown</project-name>
  <project-description>Add a dropdown menu to the books page</project-description>
  <proj-path>proj/dropdown/</proj-path>
</metadata>

<spec path="proj/dropdown/SPEC.md">

# Dropdown menu on books page

## TL;DR

## Current State

// Describe the project or feature that will be changed, how it works and any relevant design

## Desired State

// Describe from the user or external system point of view how everything will work after the change

## Background and Context

// Give any details that could be relevant, recent work, or resources

## Problem

// Describe the broken user story we're trying to fix

## Solution

// Describe in high-level detail what the fix will be

## Trade-offs and alternatives

// Some other ways we could have fixed it and what benefit they would have had

## Next steps and fast follows

// Things that are out of scope, will still be broken, or that will be revealed as necessary by the work in this project

</spec>

<punchlist path="proj/dropdown/PUNCHLIST.md">

# Dropdown menu on books page

// Optional heading, only an example, should be specific to the project

## Elasticsearch changes

- [ ] First task for elasticsearch
- [ ] Second task, etc...

</punchlist>

</template-execution-plan>

## Environment

The _most important_ environment tip is for non-dev commands, run them with `shadowenv exec -- {command}` when they could rely on ruby or other environment setup. For example run `shadowenv exec -- bundle` instead of `bundle`.

Commands that needs `shadowenv` include:

- bundle
- gem
- bin/rails
- anything with dev or `/opt/dev/bin/dev`

When debugging, always use `puts` over `Rails.log` or similar. Puts is much better because I can always see the output.

For the dev command...

- I have a program called 'dev' that I reference a lot in commands for things like build and test
- If you need to use this command, call it as `/opt/dev/bin/dev`
- For example, if I say "I ran dev test and found a failing test." I mean `/opt/dev/bin/dev test`
- When I run tests, I find that running by name causes problems due to my shell sometimes. I prefer to run with the line number
- For example I prefer running tests like `/opt/dev/bin/dev test app/controllers/some_controller.rb:50`

## Claude's Behavior

This section is very important.

- I like it when Claude tries to do things on its own rather than asking permission
- I like it when Claude documents what it's doing by modifying the punch list to show what is done
- I like when Claude adds things to the punch list when it realizes more work needs to be done
- Claude should be honest, kind, and concise
- Claude should prefer the active voice and clean and clear language

## Miscellaneous

Here are a few pointers specific to my development flow...

- I usually keep a hidden folder in my projects called `miller`
- It is hidden by a git ignore file that contains `*` so anything there is important to CLAUDE but has no effect on the project
- I put a file called `miller/failed` with the pasted output of either a Build Kite run (HTML) or a local run (TEXT)
- I have scripts called `txt-failed-tests` and `buildkite-failed-tests` that parse those and run tests for me
- For example, if I'm running "text tests" that usually means I ran `txt-failed-tests miller/failed`
