# Agent Development Guide

A file for [guiding coding agents](https://agents.md/) working on this
repository: a Nix flake defining NixOS and home-manager configurations for
delay's hosts.

## Repository layout

`flake.nix` uses [flake-parts](https://flake.parts) with in-repo module
auto-discovery (`modules/flake/module-tree.nix`): every `.nix` file under
`modules/` is imported automatically. Adding a file wires it in; there is
no central import list to update. A directory containing a
`.skip-subtree` sentinel file is excluded from discovery — use it for
support material (packages, helper libs, data) that is not a flake-parts
module.

- `modules/flake/` — flake-level wiring (systems, overlays, checks)
- `modules/lib/` — shared helpers exposed as `self.lib.*`; implementation
  files live under `modules/lib/internal/`
- `modules/nixos/` — NixOS modules (`flake.nixosModules.*`)
- `modules/nixos.profiles/` — profiles composing NixOS modules
- `modules/nixos.hosts/` — one directory per host: `fwk`, `nyx`, `term-x1p`,
  `jump-jp`, `node-skl`, `site-jp`, `site-fr`, `gate-jp`, `gate-fr`, `iso`
- `modules/home/` — home-manager modules
- `modules/home.profiles/` — home-manager profiles

## Build, test, format

The commands below are devenv scripts, available on `PATH` inside the dev
shell. direnv activates it automatically (`.envrc` runs `use devenv`); without
direnv, run them through `devenv shell -- <command>`.

- **Format:** `format` — treefmt wrapper running nixfmt, shfmt, and stylua.
  Run it after editing Nix, shell, or Lua files.
- **Validate:** `check` — `nix flake check --show-trace`.
- **Build (current host):** `build` — `nixos-rebuild build --flake .` plus an
  `nvd` diff against the running system. Builds only; never switches.
- **Build (specific host):**
  `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
  with `<host>` from the list above.
- **Evaluate one option:**
  `nix eval .#nixosConfigurations.<host>.config.<option.path>` — the fastest
  signal when changing module wiring.
- `rebuild`, `sys-upgrade`, `rollback`, `deploy`, and `remote-*` change
  running systems. Do not run them unless the user explicitly asks.

## Vendored patches

Unreleased upstream fixes are vendored as `.patch` files committed next to
the consuming module, in a subdirectory named after the package — e.g.
`modules/nixos/github-backup/pr-521-watched-repositories-endpoint.patch`.
Name GitHub PR patches `pr-<N>-<slug>.patch`. Apply them with
`overrideAttrs (attrs: { patches = (attrs.patches or [ ]) ++ [ ./… ]; })`
at the consuming site, preceded by a comment explaining the why and a
`TODO(<release>): Drop this override once …` marker, where `<release>` is
the NixOS release expected to ship the fix (e.g. `TODO(26.11)`). When
upgrading to a release, grep for its `TODO(` marker to find overrides due
for removal.

## Arcshell

`modules/home/arcshell/` contains arc-shell, a bespoke Quickshell (Qt6/QML)
desktop shell for Hyprland. Before working in that directory, read
[`modules/home/arcshell/SKILL.md`](modules/home/arcshell/SKILL.md) — it
documents the layout, panel architecture, design tokens, QML conventions, the
dev workflow for running an instance against the working tree, and hard-won
Hyprland gotchas.

## File search MCP

The workstation home-manager config ships `fff-mcp` globally (wired in
`~/.omp/agent/mcp.json` via `modules/home/llm-agents/programs-omp.nix`),
exposing frecency-ranked `find_files` / `grep` / `multi_grep` MCP tools —
prefer them for filename and content search when available.

## Version control: Jujutsu (jj)

This repository is a [jj](https://jj-vcs.github.io/jj/) repo colocated with
git (`.jj/` and `.git/` both exist at the root).

- Prefer `jj` commands over `git` ones: `jj st`, `jj diff`, `jj log`,
  `jj commit`, `jj squash`, …
- If a `git` command is required, use read-only ones only (e.g. `git log`,
  `git show`, `git diff`).
- Exception: `git add -N <file>` (intent-to-add) is allowed — and required
  after creating a file. Nix flake commands only see git-tracked files; a new
  untracked file fails evaluation with
  `error: Path '<file>' … is not tracked by Git`.
- Every other mutating operation (commit, squash, rebase, bookmarks, undo)
  goes through jj.
