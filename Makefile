# The name of the configuration in the flake.
NIXNAME ?= vm-aarch64

# Connectivity info for NixOS VM.
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= delay

# Get the path to this Makefile and directory.
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# SSH options that are used. These aren't meant to be overridden but are reused a lot so we just
# store them up here.
PRE_BOOTSTRAP_SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
SSH_OPTIONS=-o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# First run on darwin (equivalent to `nixos-install` to bootstrap the system).
darwin/bootstrap:
	nix run nix-darwin -- switch --flake .

# Copy the configuration to the VM and run the bootstrap script.
vm/bootstrap: flake/ hosts/ modules/ users/ flake.lock flake.nix bootstrap-vm.sh
	tar -C $(MAKEFILE_DIR) -czf - $^ \
		| ssh $(PRE_BOOTSTRAP_SSH_OPTIONS) -p$(NIXPORT) -lroot $(NIXADDR) \
		'mkdir -p /nix-config && tar -C /nix-config -xmzf - && bash /nix-config/bootstrap-vm.sh $(NIXNAME)'

# Copy secrets to the VM. Expects the guest OS to be fully installed.
vm/copy-secrets:
	for key in github git-commit-signing linode; do \
		sekrets read-ssh-key -k $$key -o - \
			| ssh $(SSH_OPTIONS) -p$(NIXPORT) -l$(NIXUSER) $(NIXADDR) \
			"bash -c \"install -m 400 <(dd) \$$HOME/.ssh/$$key\""; \
	done
