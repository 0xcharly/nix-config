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

# Copy the configuration to the VM and run the bootstrap script.
# The GitHub SSH key is copied over to fetch flake inputs that point to private
# GitHub repositories.
# NOTE: the `--skip-passphrase` option is suboptimal, but the key only lives in
# RAM until the install completes and the machine reboots.
# TODO: remove secret once Ghostty is public.
vm/bootstrap: parts/ hosts/ modules/ users/ flake.lock flake.nix bootstrap-vm.sh
	sekrets read-ssh-key -k github --skip-passphrase -o - \
		| ssh $(PRE_BOOTSTRAP_SSH_OPTIONS) -p$(NIXPORT) -lroot $(NIXADDR) \
		"bash -c \"install -D -m 400 <(dd) \$$HOME/.ssh/github\""
	tar -C $(MAKEFILE_DIR) -czf - $^ \
		| ssh $(PRE_BOOTSTRAP_SSH_OPTIONS) -p$(NIXPORT) -lroot $(NIXADDR) \
		'mkdir -p /nix-config && tar -C /nix-config -xmzf - && nix-shell -p git --run "bash /nix-config/bootstrap-vm.sh $(NIXNAME)"'
