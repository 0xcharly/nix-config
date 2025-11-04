# NixOS System Configurations

This repository contains my NixOS system configurations.

This repository was originally forked from [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config), and then adapted to my needs and hosts.

I don't claim to be an expert at Nix or NixOS and have yet to hone my knowledge of the overall ecosystem.

> [!WARNING]
>
> **Don't do this without reading the source.**
>
> This repository's configuration is heavily tuned to my preferences. If you blindly run this, your systems may be changed in ways that you don't want.

## NixOS: Workstation

## NixOS: NAS

## NixOS: Linode VM

(Derived from https://www.linode.com/docs/guides/install-nixos-on-linode/)

The Linode images use 2 disks:

- /dev/sda: System
- /dev/sdb: Swap

For installation, the ISO image is written to the Swap partition. This partition is overwritten during installation. On reboot, this partition is normally mounted by the system as a swap.

### Steps

1. Create two disk images:

   - SWAP: 2048mb (raw)
   - SYSTEM: rest (raw)

1. Boot in rescue mode with:

   - /dev/sda -> SWAP
   - /dev/sdb -> SYSTEM

1. Once booted into Finnix (step 2):

   ```sh
   update-ca-certificates
   curl -L <ISO_URL> | tee >(dd of=/dev/sda) | sha256sum
   ```

1. Create a "Boot" configuration profile:

   - Kernel: Direct Disk
   - /dev/sda -> SYSTEM
   - /dev/sdb -> SWAP
   - Root device: /dev/sdb
   - Helpers: distro and auto network helpers = off
   - Leave others on their defaults

1. If deploying on a Nanode (Linode 1Go), consider temporarily resizing the machine to at least a Shared Linode 2Go plan to improve performances and avoid OOM during system installation. Do this after creating the disk to facilitate the downsizing process post install.

1. Boot into installer profile and setup session:

   ```sh
   passwd  # set `nixos` user passwd
   ```

1. Get public IPv4 address (ipconfig from the machine or from Linode UI).

1. Remote install (from a x86_64-linux machine):

   ```sh
   provision-linode <ADDR> <HOSTNAME>
   ```

1. Turn off and edit the "Boot" profile:

   - Root device: /dev/sda

1. Resize to Nanode (Linode 1Go) if necessary.

## macOS/Darwin

> [!WARNING]
>
> Unlike NixOS, it is more troublesome to revert a the effect of nix-darwin, since there's no snapshot to restore to.
>
> Read the source!

### `nix-darwin` setup

I share some of my Nix configurations with my Mac host and use Nix to manage _most_ aspects of my macOS installation, too. This uses the [nix-darwin](https://github.com/LnL7/nix-darwin) project. I don't manage _everything_ with Nix yet, in particular I don't manage most of my GUI apps. I plan to migrate some of those in time. My system settings, Homebrew, etc. are however already managed by Nix.

To utilize the macOS setup, first install Nix using some Nix installer.

I use the [nix-installer](https://github.com/DeterminateSystems/nix-installer) by Determinate Systems. The point is just to get the `nix` CLI with flake support installed.

Once installed, clone this repo and bootstrap the `nix-darwin` installation:

```sh
nix run nix-darwin -- switch --flake .
```

If there are any errors, follow the error message (e.g. some folders may need permissions changed, etc…). That's it.

### `nix-darwin` maintenance

Once `nix-darwin` is installed, successive incremental changes are applied with `darwin-rebuild`:

```sh
just switch
```

### Troubleshooting

You may get an error of the form:

```
2024-08-09 23:03:08.941 defaults[91177:19870960] Could not write domain com.apple.universalaccess; exiting
```

This usually means that your terminal does not have "Full Disk Access".

Enable it in System Preferences > Security & Privacy > Privacy > Full Disk Access.

## Nix on a Linux host (not NixOS)

> [!WARNING]
>
> **This configuration is not properly tested**.
>
> This is currently a work-in-progress attempt at supporting Linux hosts on
> which I can't install NixOS.

### Home Manager setup

Home Manager is already used to manage all of my user configuration (i.e. dotfiles, scripts and more). On non-NixOS hosts, Home Manager can be used standalone.

To utilize the Home Manager standalone setup, first install Nix using some Nix installer.

I use the [nix-installer](https://github.com/DeterminateSystems/nix-installer) by Determinate Systems.com, but it should work with any install, including from the system's package manager. The point is just to get the `nix` CLI with flake support installed.

Once installed, clone this repo and bootstrap the `home-manager` installation:

```sh
nix run home-manager -- switch --flake .
```

If there are any errors, follow the error message (e.g. some folders may need permissions changed, etc…). That's it.

### `home-manager` maintenance

Once `home-manager` is installed, successive incremental changes are applied with `home-manager`:

```sh
just switch
```

### Nix client configuration

Note that some attributes in `~/.config/nix/nix.conf` are ignored in standalone mode, namely `trusted-users`, which resuls in many warnings:

```
warning: ignoring untrusted substituter 'https://<prefix>.cachix.org', you are not a trusted user.
Run `man nix.conf` for more information on the `substituters` configuration option.
```

A workaround is to add the current user to the `trusted-users` list directly in the system configuration file `/etc/nix/nix.conf`:

```sh
sudo echo "trusted-users = $(whoami)" >> /etc/nix/nix.conf
```

## Nix cheatsheet

Some arbitrary collection of commands that have been useful in the past.

### Repair Nix store

```sh
nix-store --verify --repair
nix-store --gc
nix-collect-garbage -d
```

## Secrets management

Most secrets are encrypted and stored in a private repository.

Secrets for provisioning are stored in a self-hosted VaultWarden instance, and fetched via the bitwarden CLI.

After provisioning, a host needs to first login to the custom instance:

```sh
bw config server <url>
bw login
```
