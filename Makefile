# Connectivity info for NixOS VM.
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= delay

# Get the path to this Makefile and directory.
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# The name of the configuration in the flake.
NIXNAME ?= vm-aarch64

# Auto OS selection in commands below.
UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
	# Partially managed nix-darwin machine.
	CONFIG_PREFIX := darwinConfigurations
	REBUILD_COMMAND := darwin-rebuild
else ifeq ($(grep ^NAME= /etc/os-release |cut -d= -f2), NixOS)
	# Fully managed NixOS machine.
	CONFIG_PREFIX := nixosConfigurations
	REBUILD_COMMAND := sudo nixos-rebuild
else
	# Other Linux distribution managed via Home Manager standalone.
	CONFIG_PREFIX := homeConfigurations
	REBUILD_COMMAND := home-manager
endif

# Enable flake support.
REBUILD_OPTIONS=--option accept-flake-config true --show-trace

# SSH options that are used. These aren't meant to be overridden but are reused a lot so we just
# store them up here.
PRE_BOOTSTRAP_SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
SSH_OPTIONS=-o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# These switch/test commands are mostly for self documentation. I usually run
# them manually from the command line.
switch:
	$(REBUILD_COMMAND) $(REBUILD_OPTIONS) switch --flake .

test:
	$(REBUILD_COMMAND) $(REBUILD_OPTIONS) test --flake .

# This builds the given configuration and pushes the results to the cache. This
# does not alter the current running system. This requires cachix authentication
# to be configured out of band.
# TODO: redesign cachix authentication on NixOs since I moved away from
# 1Password in the VM.
cache:
	nix build '.#$(CONFIG_PREFIX).$(NIXNAME).config.system.build.toplevel' --json \
		| jq -r '.[].outputs | to_entries[].value' \
		| op plugin run -- cachix push 0xcharly-nixos-config

# First run on darwin (equivalent to `nixos-install` to bootstrap the system).
darwin/bootstrap:
	nix run nix-darwin -- switch --flake .

# Copy the configuration to the VM and run the bootstrap script.
vm/bootstrap: hosts/ lib/ modules/ users/ flake.lock flake.nix bootstrap-vm.sh
	tar -C $(MAKEFILE_DIR) -czf - $^ \
		| ssh $(PRE_BOOTSTRAP_SSH_OPTIONS) -p$(NIXPORT) -lroot $(NIXADDR) \
		'mkdir -p /nix-config && tar -C /nix-config -xzf - && bash /nix-config/bootstrap-vm.sh $(NIXNAME)'

# Copy secrets to the VM. Expects the guest OS to be fully installed.
vm/copy-secrets:
	for key in github git-commit-signing linode; do \
		sekrets read-ssh-key -k $$key -o - \
			| ssh $(SSH_OPTIONS) -p$(NIXPORT) -l$(NIXUSER) $(NIXADDR) \
			"bash -c \"install -m 400 <(dd) \$$HOME/.ssh/$$key\""; \
	done
