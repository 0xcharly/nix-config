import '.justfile.incl'

set dotenv-load
set dotenv-required

set shell := ['fish', '-c']

hostname := `hostname`
rebuildOptions := '--option accept-flake-config true --show-trace'

[doc('List all available commands')]
[group('nix')]
[private]
default:
    @just --list

[doc("Rebuild the current darwin host's configuration and permanently switch to it")]
[group('nix')]
[macos]
switch:
    darwin-rebuild {{ rebuildOptions }} switch --flake .

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

[doc('Update the given flake inputs')]
[group('nix')]
update +inputs:
    for input in {{ inputs }}; nix flake update --flake . $input; end

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

# Generate ~/.config/nix/nix.conf and populate the access token for github.com
# from 1Password.

[doc('Generate ~/.config/nix/nix.conf')]
[group('secrets')]
[macos]
generate-access-tokens-conf:
    install -D -m 400 (echo "extra-access-tokens = github.com=$( \
        op read 'op://Private/GitHub Fine-grained token for Nix/password' \
    )" | psub) $HOME/.config/nix/access-tokens.conf

[doc('Copy secrets to local host')]
[group('secrets')]
[macos]
copy-secrets:
    #! /usr/bin/env fish
    for key in bitbucket github git-commit-signing linode skullkid vm
      install -D -m 400 (sekrets read-ssh-key -k $key -o - | psub) $HOME/.ssh/$key
    end

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
    tar -C {{ justfile_directory() }} -czf - parts/ hosts/ modules/ users/ flake.lock flake.nix bootstrap-vm.sh \
      | ssh {{ pre_bootstrap_ssh_options }} -p{{ ssh_port }} -lroot {{ addr }} \
      'mkdir -p /nix-config && tar -C /nix-config -xmzf - && nix-shell -p git --run "bash /nix-config/bootstrap-vm.sh {{ vm_name }}"'

    # A host key-pair is regenerated after a successful installation.
    # Remove any existing entry for given IP in ~/.ssh/known_hosts.
    nix eval ".#nixosConfigurations.{{ vm_name }}.config.networking.interfaces" --apply "interfaces: let
      inherit (builtins) attrValues concatLists map;
    in concatLists (map (i: map (a: a.address) i.ipv4.addresses) (attrValues interfaces))" \
      | jq --raw-output '.[]' | while read --list host
      ssh-keygen -R $host 2> /dev/null
    end

[doc('Copy ~/.config/nix/nix.conf to remote host')]
[group('secrets')]
[macos]
ssh-generate-access-tokens-conf host:
    echo "extra-access-tokens = github.com=$( \
        op read 'op://Private/GitHub Fine-grained token for Nix/password' \
    )" | ssh {{ ssh_options }} -p{{ ssh_port }} -l{{ ssh_user }} {{ host }} \
         "bash -c \"install -D -m 400 <(dd) \$HOME/.config/nix/access-tokens.conf\""

[doc('Copy secrets to remote host')]
[group('secrets')]
[macos]
ssh-copy-secrets host:
    #! /usr/bin/env fish

    # Expects the guest OS to be fully installed.
    for key in github git-commit-signing
      sekrets read-ssh-key -k $key -o - \
          | ssh {{ ssh_options }} -p{{ ssh_port }} -l{{ ssh_user }} {{ host }} \
          "bash -c \"install -D -m 400 <(dd) \$HOME/.ssh/$key\""
    end

[doc('Copy Cachix authentication token to remote host')]
[group('secrets')]
[macos]
ssh-init-cachix host:
    op read 'op://Private/Cachix Auth Tokens/token' \
        | ssh {{ ssh_options }} -p{{ ssh_port }} -l{{ ssh_user }} {{ host }} \
        "nix-shell -p cachix --run 'cachix authtoken --stdin'"

[doc("Copy terminal's terminfo to a remote machine")]
[group('remotes')]
[macos]
ssh-copy-terminfo addr:
    infocmp -x | ssh {{ ssh_options }} -p{{ ssh_port }} -l{{ ssh_user }} {{ addr }} -- tic -x -
