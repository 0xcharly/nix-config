import 'justfile.incl'

set shell := ['fish', '-c']

hostname := `hostname`
rebuildOptions := '--option accept-flake-config true --show-trace'

[doc('List all available commands')]
[private]
default:
    @just --list

[doc("Rebuild the current darwin host's configuration")]
[macos]
switch:
    darwin-rebuild {{ rebuildOptions }} switch --flake .

[doc("Rebuild the current host's configuration")]
[linux]
switch:
    #! /usr/bin/env fish
    if test (grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"
      set REBUILD_COMMAND "sudo nixos-rebuild"
    else
      set REBUILD_COMMAND "home-manager switch -b hm.bak"
    end
    eval $REBUILD_COMMAND {{ rebuildOptions }} switch --flake .

[doc("Rebuild the current host's configuration")]
[linux]
test:
    #! /usr/bin/env fish
    if test (grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"
      sudo nixos-rebuild {{ rebuildOptions }} test --flake .
    end

[doc('Update the given flake input')]
[macos]
update input:
  nix flake update {{ input }}

[doc('Update the given flake input')]
[linux]
update input:
  nix flake lock --update-input {{ input }}

# Builds the current darwin host's configuration and caches the results.
#
# This does not alter the current running system. Requires cachix authentication
# to be configured out of band.
[doc('Build the given configuration and push the results to the cache')]
[macos]
cache:
    nix build '.#darwinConfigurations.{{ hostname }}.config.system.build.toplevel' --json \
      | jq -r '.[].outputs | to_entries[].value' \
      | op plugin run -- cachix push 0xcharly-nixos-config

# Builds the current host's configuration (NixOS or HM) and caches the results.
#
# This does not alter the current running system. Requires cachix authentication
# to be configured out of band.
[doc('Build the given configuration and push the results to the cache')]
[linux]
cache:
    #! /usr/bin/env fish
    if test (grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"
      set CONFIG_PREFIX "nixosConfigurations"
    else
      set CONFIG_PREFIX "homeConfigurations"
    end
    nix build ".#$CONFIG_PREFIX.{{ hostname }}.config.system.build.toplevel" --json \
      | jq -r '.[].outputs | to_entries[].value' \
      | cachix push 0xcharly-nixos-config
