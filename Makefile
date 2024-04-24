# Connectivity info for Linux VM
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= delay

# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# The name of the nixosConfiguration in the flake
NIXNAME ?= vm-aarch64

# SSH options that are used. These aren't meant to be overridden but are
# reused a lot so we just store them up here.
SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# We need to do some OS switching below.
UNAME := $(shell uname)

switch:
ifeq ($(UNAME), Darwin)
	nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXNAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIXNAME}"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake ".#${NIXNAME}"
endif

test:
ifeq ($(UNAME), Darwin)
	nix build ".#darwinConfigurations.${NIXNAME}.system"
	./result/sw/bin/darwin-rebuild test --flake "$$(pwd)#${NIXNAME}"
else
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild test --flake ".#$(NIXNAME)"
endif

# This builds the given NixOS configuration and pushes the results to the
# cache. This does not alter the current running system. This requires
# cachix authentication to be configured out of band.
# TODO: setup own cachix instance.
cache:
	nix build '.#nixosConfigurations.$(NIXNAME).config.system.build.toplevel' --json \
		| jq -r '.[].outputs | to_entries[].value' \
		| cachix push mitchellh-nixos-config

# bootstrap a brand new VM. The VM should have NixOS ISO on the CD drive
# and just set the password of the root user to "root". This will install
# NixOS. After installing NixOS, you must reboot and set the root password
# for the next step.
#
# NOTE(mitchellh): I'm sure there is a way to do this and bootstrap all
# in one step but when I tried to merge them I got errors. One day.
vm/bootstrap0:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted -s /dev/sda -- mklabel gpt; \
		parted -s /dev/sda -- mkpart primary 512MB -8GB; \
		parted -s /dev/sda -- mkpart primary linux-swap -8GB 100\%; \
		parted -s /dev/sda -- mkpart ESP fat32 1MB 512MB; \
		parted -s /dev/sda -- set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos /dev/sda1; \
		mkswap -L swap /dev/sda2; \
		mkfs.fat -F 32 -n boot /dev/sda3; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.package = pkgs.nixUnstable;\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
			nix.settings.substituters = [\"https://mitchellh-nixos-config.cachix.org\"];\n \
			nix.settings.trusted-public-keys = [\"mitchellh-nixos-config.cachix.org-1:bjEbXJyLrL1HZZHBbO4QALnI5faYZppzkU4D2s0G8RQ=\"];\n \
			services.openssh.enable = true;\n \
			services.openssh.settings.PasswordAuthentication = true;\n \
			services.openssh.settings.PermitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd && reboot; \
	"

define _linode_bootstrap0
umount --force --recursive /mnt
mkfs.ext4 -F -L nixos /dev/sda
mkswap -L swap /dev/sdb
mkfs.fat -F 32 -n boot /dev/sdc
mount /dev/sda /mnt
mkdir -p /mnt/boot
mount /dev/sdc /mnt/boot
nixos-generate-config --root /mnt
sed --in-place -f - /mnt/etc/nixos/hardware-configuration.nix <<- 'EOF'
		s|swapDevices = \[ \]|swapDevices = [ { device = "/dev/disk/by-label/swap"; } ]|
		s|"/dev/disk/by-uuid/.*"|"/dev/disk/by-label/nixos"|
		s|"/dev/sdc"|"/dev/disk/by-label/boot"|
EOF
sed --in-place -f - /mnt/etc/nixos/configuration.nix <<- 'EOF'
	/system\.stateVersion = .*/a \
	nix.package = pkgs.nixUnstable;\n \
	nix.extraOptions = "experimental-features = nix-command flakes";\n \
	boot.kernelParams = [ "console=ttyS0,19200n8" ];\n \
	boot.loader.grub.extraConfig = ''\n \
		serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;\n \
		terminal_input serial;\n \
		terminal_output serial\n \
	'';\n \
	boot.loader.grub.forceInstall = true;\n \
	boot.loader.grub.device = "nodev";\n \
	boot.loader.timeout = 10;\n \
	services.openssh.enable = true;\n \
	services.openssh.settings.PasswordAuthentication = true;\n \
	services.openssh.settings.PermitRootLogin = "yes";\n \
	networking.useDHCP = false;\n \
	networking.usePredictableInterfaceNames = false;\n \
	networking.interfaces.eth0.useDHCP = true;\n \
	environment.systemPackages = with pkgs; [ inetutils mtr sysstat ];\n \
	users.users.root.initialPassword = "root";\n
EOF
nixos-install --no-root-passwd # && reboot
endef
export linode_bootstrap0 = $(value _linode_bootstrap0)

linode/bootstrap0:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) -lroot $(NIXADDR) "$$linode_bootstrap0"

# after bootstrap0, run this to finalize. After this, do everything else
# in the VM unless secrets change.
vm/bootstrap:
	NIXUSER=root $(MAKE) vm/copy
	NIXUSER=root $(MAKE) vm/switch
	ssh $(SSH_OPTIONS) -p$(NIXPORT)$(NIXUSER)@$(NIXADDR) " \
		sudo reboot; \
	"

# copy the Nix configurations into the VM.
vm/copy:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='vendor/' \
		--exclude='.git/' \
		--exclude='.git-crypt/' \
		--exclude='iso/' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ $(NIXUSER)@$(NIXADDR):/nix-config

# run the nixos-rebuild switch command. This does NOT copy files so you
# have to run vm/copy before.
vm/switch:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake \"/nix-config#${NIXNAME}\" \
	"

# Build a WSL installer
.PHONY: wsl
wsl:
	 nix build ".#nixosConfigurations.wsl.config.system.build.installer"
