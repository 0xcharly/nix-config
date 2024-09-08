# NixOS System Configurations

This repository contains my NixOS system configurations.

This repository was originally forked from
[mitchellh/nixos-config](https://github.com/mitchellh/nixos-config), and then
adapted to my needs and hosts.

I don't claim to be an expert at Nix or NixOS and have yet to hone my knowledge
of the overall ecosystem.

## How I Work

I like to use macOS as the host OS and NixOS within a VM as my primary
development environment. I use the graphical applications on the host (browser,
calendars, mail apps, Discord, etc.) but I do almost everything dev-related in
the VM.

All such graphical applications on the macOS host are installed either via the
App Store (managed with [mas](https://github.com/mas-cli/mas)), or as Homebrew
casks. Homebrew itself is installed and managed by this configuration with the
[nix-homebrew](https://github.com/zhaofengli/nix-homebrew) flake.

Homebrew is _only_ used to install casks (until I look into switching to fully
Nix-managed install).

Note that I usually full screen the VM so there isn't actually a window, and I
three-finger swipe or use other keyboard shortcuts to activate that window.

## NixOS VM on macOS host

### NixOS VM setup

> [!NOTE]
>
> This setup guide will cover VMware Fusion because that is the hypervisor I use
> day to day.
>
> The original fork of this repository also supports UTM and Parallels but I'm
> not using either so removed the configurations to simplify maintenance. I've
> also removed the Windows support (VMware Workstation and Hyper-V).
>
> Check out the repository this fork is based on if you're interested in
> restoring these:
> [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config).

#### VMware Fusion NAT configuration

This NixOS configuration expects a specific NAT subnet to be available for the
VM networking configuration (specifically, `192.168.70.*`).

To guarantee that VMware Fusion NAT configuration does match with expectations,
double check the content of the following file, and edit it as necessary:

- `/Library/Preferences/VMware\ Fusion/networking`

Specifically, the value of `VNET_8_HOSTONLY_SUBNET`:

```
answer VNET_8_HOSTONLY_SUBNET 192.168.70.0
```

Stop all VMs and close VMware Fusion before editing this file. Once updated,
restart VMware Fusion and verify that the content of these files match
expectations:

- `/Library/Preferences/VMware Fusion/vmnet8/dhcpd.conf`
- `/Library/Preferences/VMware Fusion/vmnet8/nat.conf`

See [this article](https://adis.ca/entry/2016/vmware-fusion-nat-and-static-ip/)
to learn how to configure DHCPD for the NAT.

#### VM Setup

Download the ISO from [NixOS downloads](https://nixos.org/download/#nixos-iso).
For Apple Silicon hardware, use the `aarch64` (64-bit ARM) images.

Create a VMware Fusion VM with the following settings. My configurations are
made for VMware Fusion so expect issues on other virtualization solutions
without minor changes.

- ISO: NixOS 24.05 or later.
- Disk: SATA 150 GB+
- CPU/Memory: I give at least half my cores and half my RAM (up to 32GB), as
  much as you can.
- Network: Shared with my Mac.
- Remove sound card, remove video camera.
- Profile: Disable almost all keybindings

Optionally, if the VM is intended to be used with a graphical session:

- Graphics: Full acceleration, full resolution, maximum graphics RAM.

Boot the VM, and using the graphical console, change the root password to "root":

```sh
$ sudo su
$ passwd
# enter new password
```

At this point, verify `/dev/sda` exists. This is the expected block device where
the bootstrap script will install the OS. If you setup your VM to use SATA, this
should exist. If `/dev/nvme` or `/dev/vda` exists instead, you didn't configure
the disk properly. Note, these other block device types work fine, but you'll
have to modify the `bootstrap-vm.sh` to use the proper block device paths.

I always take a snapshot at this point, in case anything goes wrong, or simply
to quickly go back to a blank slate. I usually call it "pre-bootstrap".

Run `ifconfig` and get the local IP address of the first device. It should match
`192.168.70.YYY` if you've followed the NAT configuration section. Pass this to
the Justfile's bootstrap recipe as its parameter:

```sh
just bootstrap-vm 192.168.70.YYY
```

The Justfile defaults to setting up the `asl` VM on an Apple Silicon processor.
If you are installing a different configuration, you must change `vm_name`.

```sh
just --set vm_name vm-aarch64 bootstrap-vm 192.168.70.YYY
```

(`vm_name` must be one of the Flake-exported NixOS configurations.)

This will install setup your partitions on the VM disk image, and install NixOS
using this configuration.

If everything goes fine, the VM should reboot into a functioning OS, optionally
with graphical environment.

#### VM flavors

The Flake provides multiple NixOS configurations for setting up a VM on an Apple
Silicon processor (actively used on M1 and M3), based on whether a graphical env
is desired:

- `asl`: headless system.
- `vm-aarch64`: full-featured system with graphical environment.

### NixOS VM maintenance

At this point, I almost never use terminals on macOS ever again. I clone this
repository in the VM and I use `nixos-rebuild` to apply changes the system:

```sh
sudo nixos-rebuild switch --flake .
```

## Linode VM

### Linode VM setup

// TODO

## macOS/Darwin

> [!WARNING]
>
> **Don't do this without reading the source.**
> This repository is and always has been _my_ configurations. If you blindly run
> this, your system may be changed in ways that you don't want.
>
> Read the source!

### `nix-darwin` setup

I share some of my Nix configurations with my Mac host and use Nix to manage
_most_ aspects of my macOS installation, too. This uses the
[nix-darwin](https://github.com/LnL7/nix-darwin) project. I don't manage
_everything_ with Nix yet, in particular I don't manage apps. I plan to migrate
some of those in time. My system settings, Homebrew, etc. are however already
managed by Nix.

To utilize the Mac setup, first install Nix using some Nix installer.

I use the [nix-installer](https://github.com/DeterminateSystems/nix-installer)
by Determinate Systems.com. The point is just to get the `nix` CLI with flake
support installed.

Once installed, clone this repo and bootstrap the `nix-darwin` installation:

```sh
nix run nix-darwin -- switch --flake .
```

If there are any errors, follow the error message (e.g. some folders may need
permissions changed, etc…). That's it.

### `nix-darwin` maintenance

Once `nix-darwin` is installed, successive incremental changes are applied with
`darwin-rebuild`:

```sh
darwin-rebuild switch --flake .
```

### Troubleshooting

You may get an error of the form:

```
2024-08-09 23:03:08.941 defaults[91177:19870960] Could not write domain com.apple.universalaccess; exiting
```

This usually means that your terminal does not have "Full Disk Access".

Enable it in System Preferences > Security & Privacy > Privacy > Full Disk
Access.

## Nix on a Linux host (not NixOS)

> [!WARNING]
>
> **This configuration is untested**
> This is currently a work-in-progress attempt at supporting Linux hosts on
> which I can't install NixOS.

### Home Manager setup

Home Manager is already used to manage all of my user configuration (i.e.
dotfiles, scripts and more). On non-NixOS hosts, Home Manager can be used
standalone.

To utilize the Home Manager standalone setup, first install Nix using some Nix
installer.

I use the [nix-installer](https://github.com/DeterminateSystems/nix-installer)
by Determinate Systems.com, but it should work with any install, including from
the system's package manager. The point is just to get the `nix` CLI with flake
support installed.

Once installed, clone this repo and bootstrap the `home-manager` installation:

```sh
nix run home-manager -- switch --flake .
```

If there are any errors, follow the error message (e.g. some folders may need
permissions changed, etc…). That's it.

### `home-manager` maintenance

Once `home-manager` is installed, successive incremental changes are applied with
`home-manager`:

```sh
home-manager switch --flake .
```

### Nix client configuration

Note that some attributes in `~/.config/nix/nix.conf` are ignored in standalone
mode, namely `trusted-users`, which resuls in many warnings:

```
warning: ignoring untrusted substituter 'https://<prefix>.cachix.org', you are not a trusted user.
Run `man nix.conf` for more information on the `substituters` configuration option.
```

A workaround is to add the current user to the `trusted-users` list directly in
the system configuration file `/etc/nix/nix.conf`:

```sh
sudo echo "trusted-users = $(whoami)" >> /etc/nix/nix.conf
```
