# Connectivity info for Linux VM.
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= delay

# Get the path to this Makefile and directory.
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# The name of the nixosConfiguration in the flake.
NIXNAME ?= vm-aarch64

# Enable flake support.
NIXOS_REBUILD_OPTIONS=--option accept-flake-config true --show-trace

# SSH options that are used. These aren't meant to be overridden but are reused a lot so we just
# store them up here.
PRE_BOOTSTRAP_SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
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

darwin-corp/switch:
	darwin-rebuild-corp switch --flake .

darwin/test:
	darwin-rebuild test --flake .

darwin-corp/test:
	darwin-rebuild-corp test --flake .

# This builds thgiven nix-darwin configuration and pushes the results to the
# cache. This does not alter the current running system. This requires cachix
# authentication to be configured out of band.
darwin/cache:
	nix build '.#darwinConfigurations.$(NIXNAME).config.system.build.toplevel' --json \
		| jq -r '.[].outputs | to_entries[].value' \
		| op plugin run -- cachix push 0xcharly-nixos-config

vm/bootstrap:
	# Set up the SSH key for the root user for subsequent steps.
	echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/bLz52u0dTFYTfJelVbXbU+VK7H4OXgre/8Mgx1+cq" \
		| ssh $(PRE_BOOTSTRAP_SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) 'install -DTm 400 <(dd) $$HOME/.ssh/authorized_keys'
	# Copy the configuration to the VM to run the bootstrap script.
	tar -C $(MAKEFILE_DIR) \
		-czf - hosts/ lib/ modules/ users/ flake.lock flake.nix bootstrap-vm.sh \
		|ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) 'mkdir -p /nix-config && tar xzf - -C /nix-config'
	# Run the bootstrap script on the VM.
	ssh $(SSH_OPTIONS) -p$(NIXPORT) -lroot $(NIXADDR) "bash /nix-config/bootstrap-vm.sh $(NIXNAME)"
	# Wait for the VM to come back up.
	while ! ping -c 1 $(NIXADDR) &>/dev/null; do :; done
	until ssh $(SSH_OPTIONS) -p$(NIXPORT) -l$(NIXUSER) $(NIXADDR) 'true'; do sleep 1; done
	# Copy the secrets to the VM.
	$(MAKE) vm/copy-secrets

vm/copy-secrets:
	# Expects fish shell on the guest.
	# If using a POSIX shell, use Process Substitution syntax instead, e.g. `<(dd)`:
	# https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Process-Substitution
	sekrets read-ssh-key -k github -o - \
		| ssh $(SSH_OPTIONS) -p$(NIXPORT) -l$(NIXUSER) $(NIXADDR) 'install -m 400 (psub) $$HOME/.ssh/github'
	sekrets read-ssh-key -k git-commit-signing -o - \
		| ssh $(SSH_OPTIONS) -p$(NIXPORT) -l$(NIXUSER) $(NIXADDR) 'install -m 400 (psub) $$HOME/.ssh/git-commit-signing'
	sekrets read-ssh-key -k linode -o - \
		| ssh $(SSH_OPTIONS) -p$(NIXPORT) -l$(NIXUSER) $(NIXADDR) 'install -m 400 (psub) $$HOME/.ssh/linode'
