set shell := ['fish', '-c']

hostname := `hostname`
rebuildOptions := '--option accept-flake-config true --show-trace'

[doc('List all available commands')]
[group('nix')]
[private]
default:
    @just --list

[doc('Format all source files')]
[group('dev')]
fmt:
    treefmt

[doc("Rebuild the current darwin host's configuration and permanently switch to it")]
[group('nix')]
[macos]
switch:
    sudo darwin-rebuild {{ rebuildOptions }} switch --flake .

[doc("Rebuild the current NixOS/HM host's configuration and permanently switch to it")]
[group('nix')]
[linux]
switch:
    #! /usr/bin/env fish
    if test (grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"
      sudo nixos-rebuild {{ rebuildOptions }} switch --flake .
    else
      home-manager {{ rebuildOptions }} switch -b hm.bak --flake .
    end

[doc("Rebuild the current NixOS host's configuration and temporary switch to it")]
[group('nix')]
[linux]
test:
    #! /usr/bin/env fish
    if test (grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"
      sudo nixos-rebuild {{ rebuildOptions }} test --flake .
    end

[doc("Run Nix Store garbage collection")]
[group('nix')]
[linux]
gc:
    nix-collect-garbage --delete-older-than 7d

[doc('Update the given flake inputs')]
[group('nix')]
update +inputs:
    for input in {{ inputs }}; nix flake update --flake . $input; end

[doc('Update all "distribution" inputs (nixpkgs, home-manager, disko, etc.)')]
[group('nix')]
distupdate:
    @just update nixpkgs nixpkgs-darwin nixpkgs-unstable home-manager nix-darwin disko nix-index-database nix-homebrew hyperland hy3 catppuccin

[doc('Update all "nixpkgs" inputs (nixpkgs, nixpkgs-darwin, nixpkgs-unstable, nur)')]
[group('nix')]
update-nixpkgs:
    @just update nixpkgs nixpkgs-darwin nixpkgs-unstable nur

[doc('Update all "toolchain" inputs (flake-parts, etc.)')]
[group('nix')]
update-toolchain:
    @just update flake-parts git-hooks-nix treefmt-nix rust-overlay

[doc('Update all "config" inputs (nix-config-lib, nix-config-secrets, etc.)')]
[group('nix')]
update-nix-config:
    @just update nix-config-fonts nix-config-lib nix-config-nvim nix-config-secrets zellij-prime-hopper

[doc('Update all inputs')]
[group('nix')]
update-all:
    nix flake update

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

[doc('Show Home Manager news')]
[group('nix')]
hm-news:
    home-manager news --flake .

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

ssh_user := `whoami`
ssh_port := '22'
ssh_options := '-o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
pre_bootstrap_ssh_options := '-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
vm_name := "asl"

[doc('Install NixOS on a local VMWare Fusion virtual machine')]
[group('remotes')]
[macos]
bootstrap-vm addr:
    #! /usr/bin/env fish

    # Copy the configuration to the VM and run the bootstrap script.

    # Copy over the relevant bits of the config under /nix-config, and execute
    # the bootstrap script remotely.
    tar -C {{ justfile_directory() }} -czf - bin/ parts/ hosts/ modules/ users/ flake.lock flake.nix \
      | ssh {{ pre_bootstrap_ssh_options }} -p{{ ssh_port }} -lroot {{ addr }} \
      'mkdir -p /nix-config && tar -C /nix-config -xmzf - && nix-shell -p git --run "bash /nix-config/bin/bootstrap-vm.sh {{ vm_name }}"'

    # A host key-pair is regenerated after a successful installation.
    # Remove any existing entry for given IP in ~/.ssh/known_hosts.
    nix eval ".#nixosConfigurations.{{ vm_name }}.config.networking.interfaces" --apply "interfaces: let
      inherit (builtins) attrValues concatLists map;
    in concatLists (map (i: map (a: a.address) i.ipv4.addresses) (attrValues interfaces))" \
      | jq --raw-output '.[]' | while read --list host
      ssh-keygen -R $host 2> /dev/null
    end

[doc("Copy terminal's terminfo to a remote machine")]
[group('remotes')]
ssh-copy-terminfo addr:
    infocmp -x | ssh {{ ssh_options }} -p{{ ssh_port }} -l{{ ssh_user }} {{ addr }} -- tic -x -
