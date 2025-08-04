set shell := ['fish', '-c']

hostname := `hostname`

[doc('List all available commands')]
[group('nix')]
[private]
default:
    @just --list

[doc("Run Nix Store garbage collection")]
[group('nix')]
[linux]
gc:
    nix-collect-garbage --delete-older-than 7d

# Builds the current darwin host's configuration and caches the results.
#
# This does not alter the current running system. Requires cachix authentication
# to be configured out of band.

[doc('Build the given configuration and push the results to the cache')]
[group('nix')]
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
[group('nix')]
[linux]
cache config=hostname:
    #! /usr/bin/env fish
    if test (grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"
      set CONFIG_PREFIX "nixosConfigurations"
    else
      set CONFIG_PREFIX "homeConfigurations"
    end
    nix build ".#$CONFIG_PREFIX.{{ config }}.config.system.build.toplevel" --json \
      | jq -r '.[].outputs | to_entries[].value' \
      | cachix push 0xcharly-nixos-config

[doc('Install NixOS on a remove Linode virtual machine')]
[group('remotes')]
[linux]
deploy-linode addr:
    bash {{ justfile_directory() }}/bin/deploy-linode.sh {{ addr }}

[doc('Install NixOS on a NAS machine')]
[group('remotes')]
[linux]
deploy-nas addr nas_hostname:
    bash {{ justfile_directory() }}/bin/deploy-nas.sh {{ addr }} {{ nas_hostname }}

[doc('Install NixOS on a remote machine')]
[group('remotes')]
[linux]
deploy-nixos addr hostname:
    bash {{ justfile_directory() }}/bin/deploy-nixos.sh {{ addr }} {{ hostname }}

[doc("Copy terminal's terminfo to a remote machine")]
[group('remotes')]
ssh-copy-terminfo addr:
    infocmp -x | ssh -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no {{ addr }} -- tic -x -
