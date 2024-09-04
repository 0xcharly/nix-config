import '.justfile.incl'

set shell := ['fish', '-c']

hostname := `hostname`
rebuildOptions := '--option accept-flake-config true --show-trace'

[doc('List all available commands')]
[group('nix')]
[private]
default:
    @just --list

[doc("Rebuild the current darwin host's configuration")]
[group('nix')]
[macos]
switch:
    darwin-rebuild {{ rebuildOptions }} switch --flake .

[doc("Rebuild the current host's configuration")]
[group('nix')]
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
[group('nix')]
[linux]
test:
    #! /usr/bin/env fish
    if test (grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"
      sudo nixos-rebuild {{ rebuildOptions }} test --flake .
    end

[doc('Update the given flake input')]
[group('nix')]
[macos]
update input:
    nix flake update {{ input }}

[doc('Update the given flake input')]
[group('nix')]
[linux]
update input:
    nix flake lock --update-input {{ input }}

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
generate-nix-conf:
    install -D -m 400 (echo "access-tokens = github.com=$( \
        op read 'op://Private/GitHub Fine-grained token for Nix/password' \
    )" | psub) $HOME/.config/nix/nix.conf

ssh_user := `whoami`
ssh_port := '22'
ssh_options := '-o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
pre_bootstrap_ssh_options := '-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

[doc('Install NixOS on a local VMWare Fusion virtual machine')]
[group('bootstrap')]
[macos]
bootstrap-vm-aarch64 addr:
    #! /usr/bin/env fish

    # Copy the configuration to the VM and run the bootstrap script. The GitHub
    # SSH key is copied over to fetch flake inputs that point to private GitHub
    # repositories.

    # NOTE: the `--skip-passphrase` option is suboptimal, but the key only lives
    # in RAM until the install completes and the machine reboots.
    # TODO: remove secret once Ghostty is public.
    sekrets read-ssh-key -k github --skip-passphrase -o - \
      | ssh {{ pre_bootstrap_ssh_options }} -p{{ ssh_port }} -lroot {{ addr }} \
      'bash -c "install -D -m 400 <(dd) \$HOME/.ssh/github"'
    tar -C {{ justfile_directory() }} -czf - parts/ hosts/ modules/ users/ flake.lock flake.nix bootstrap-vm.sh \
      | ssh {{ pre_bootstrap_ssh_options }} -p{{ ssh_port }} -lroot {{ addr }} \
      'mkdir -p /nix-config && tar -C /nix-config -xmzf - && nix-shell -p git --run "bash /nix-config/bootstrap-vm.sh vm-aarch64"'

[doc('Install NixOS on a local VMWare Fusion virtual machine')]
[group('bootstrap')]
[macos]
bootstrap-asl addr:
    #! /usr/bin/env fish

    # Copy the configuration to the VM and run the bootstrap script. The GitHub
    # SSH key is copied over to fetch flake inputs that point to private GitHub
    # repositories.

    # NOTE: the `--skip-passphrase` option is suboptimal, but the key only lives
    # in RAM until the install completes and the machine reboots.
    # TODO: remove secret once Ghostty is public.
    sekrets read-ssh-key -k github --skip-passphrase -o - \
      | ssh {{ pre_bootstrap_ssh_options }} -p{{ ssh_port }} -lroot {{ addr }} \
      'bash -c "install -D -m 400 <(dd) \$HOME/.ssh/github"'
    tar -C {{ justfile_directory() }} -czf - parts/ hosts/ modules/ users/ flake.lock flake.nix bootstrap-vm.sh \
      | ssh {{ pre_bootstrap_ssh_options }} -p{{ ssh_port }} -lroot {{ addr }} \
      'mkdir -p /nix-config && tar -C /nix-config -xmzf - && nix-shell -p git --run "bash /nix-config/bootstrap-vm.sh asl"'

[doc('Copy secrets to the host')]
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
