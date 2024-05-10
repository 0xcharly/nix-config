# Connectivity info for Linux VM
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= delay

# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# The name of the nixosConfiguration in the flake
NIXNAME ?= vm-aarch64

# SSH options that are used. These aren't meant to be overridden but are reused a lot so we just
# store them up here.
BOOTSTRAP0_SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
NIXOS_REBUILD_OPTIONS=--option accept-flake-config true --show-trace
SSH_OPTIONS=-o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

switch:
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild $(NIXOS_REBUILD_OPTIONS) switch --flake .

test:
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild $(NIXOS_REBUILD_OPTIONS) test --flake .

# This builds the given NixOS configuration and pushes the results to the
# cache. This does not alter the current running system. This requires
# cachix authentication to be configured out of band.
cache:
	nix build '.#nixosConfigurations.$(NIXNAME).config.system.build.toplevel' --json \
		| jq -r '.[].outputs | to_entries[].value' \
		| op plugin run -- cachix push 0xcharly-nixos-config

darwin/bootstrap:
	nix run nix-darwin -- switch --flake .

darwin/switch:
	darwin-rebuild switch --flake .

darwin/test:
	darwin-rebuild test --flake .

# This builds the given nix-darwin configuration and pushes the results to the
# cache. This does not alter the current running system. This requires cachix
# authentication to be configured out of band.
darwin/cache:
	nix build '.#darwinConfigurations.$(NIXNAME).config.system.build.toplevel' --json \
		| jq -r '.[].outputs | to_entries[].value' \
		| op plugin run -- cachix push 0xcharly-nixos-config

# bootstrap a brand new VM. The VM should have NixOS ISO on the CD drive and
# just set the password of the root user. This will install NixOS and reboot.
#
# TODO(delay): do this and vm/bootstrap all in one step.
vm/bootstrap0:
	ssh $(BOOTSTRAP0_SSH_OPTIONS) -p$(NIXPORT) -lroot $(NIXADDR) "bash -" < $(MAKEFILE_DIR)/bootstrap0-$(NIXNAME).sh

# After bootstrap0, run this to finalize. After this, do everything else in the
# VM.
vm/bootstrap:
	NIXUSER=root $(MAKE) vm/copy
	NIXUSER=root $(MAKE) vm/switch
	ssh $(SSH_OPTIONS) -p$(NIXPORT) -l$(NIXUSER) $(NIXADDR) "sudo reboot"

# Copy the Nix configurations into the VM.
vm/copy:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='vendor/' \
		--exclude='.gitignore' \
		--exclude='.gitconfig' \
		--exclude='.git/' \
		--exclude='.github/' \
		--exclude='.git-crypt/' \
		--exclude='iso/' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ $(NIXUSER)@$(NIXADDR):/nix-config

# Run the nixos-rebuild switch command. This does NOT copy files so you have to
# run vm/copy before.
vm/switch:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) -l$(NIXUSER) $(NIXADDR) "make -C /nix-config switch"
