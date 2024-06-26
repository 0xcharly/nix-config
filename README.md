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

>[!NOTE]
>
> This setup guide will cover VMware Fusion because that is the hypervisor I use
> day to day.
> The original fork of this repository also supports UTM and Parallels but I'm
> not using either so removed the configurations to simplify maintenance. I've
> also removed the Windows support (VMware Workstation and Hyper-V).
> Check out the repository this fork is based on if you're interested in
> restoring these:
> [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config).

Download the ISO from [NixOS downloads](https://nixos.org/download/#nixos-iso).
For Apple Silicon hardware, use the `aarch64` (64-bit ARM) images.

Create a VMware Fusion VM with the following settings. My configurations are
made for VMware Fusion so expect issues on other virtualization solutions
without minor changes.

* ISO: NixOS 24.05 or later.
* Disk: SATA 150 GB+
* CPU/Memory: I give at least half my cores and half my RAM (up to 32GB), as
  much as you can.
* Graphics: Full acceleration, full resolution, maximum graphics RAM.
* Network: Shared with my Mac.
* Remove sound card, remove video camera.
* Profile: Disable almost all keybindings

Boot the VM, and using the graphical console, change the root password to "root":

```shell
$ sudo su
$ passwd
# change to root
```

At this point, verify `/dev/sda` exists. This is the expected block device where
the bootstrap script will install the OS. If you setup your VM to use SATA, this
should exist. If `/dev/nvme` or `/dev/vda` exists instead, you didn't configure
the disk properly. Note, these other block device types work fine, but you'll
have to modify the `bootstrap-vm.sh` to use the proper block device paths.

I always take a snapshot at this point, in case anything goes wrong, or simply
to quickly go back to a blank slate. I usually call it "pre-bootstrap".

Run `ifconfig` and get the IP address of the first device. It is probably
`192.168.XXX.YYY`, but it can be anything. Pass this to the `Makefile` through
the `NIXADDR` var (either by exporting it into your environment, or on the
`make` command-line):

```shell
export NIXADDR=<VM ip address>
```

The Makefile defaults to setting up a VM on an Apple Silicon processor (actively
used on M1 and M3). If you are building for a different target, you must change
`NIXNAME` (same as `NIXADDR`).

```shell
export NIXNAME=vm-aarch64
```

Run the bootstrap target. This will install setup your partitions on the VM disk
image, and install NixOS using this configuration:

```shell
make vm/bootstrap
```

If everything goes fine, the VM should reboot into a functioning OS with
graphical environment.

### NixOS VM maintenance

At this point, I almost never use terminals on macOS ever again. I clone this
repository in the VM and I use `nixos-rebuild` to apply changes the system:

```shell
sudo nixos-rebuild switch --flake .
```

## Linode VM

### Linode VM setup

// TODO

Run `ifconfig` and get the IP address of the first device. It is probably
`192.168.XXX.YYY`, but it can be anything. Pass this to the `Makefile` through
the `NIXADDR` var (either by exporting it into your environment, or on the
`make` command-line):

```shell
export NIXADDR=<VM ip address>
```

The Makefile defaults to setting up a VM on an Apple Silicon processor (actively
used on M1 and M3). If you are building for a different target, you must change
`NIXNAME` (same as `NIXADDR`).

```shell
export NIXNAME=vm-linode
```

Run the bootstrap target. This will install setup your partitions on the VM disk
image, and install NixOS using this configuration:

```shell
make vm/bootstrap
```

If everything goes fine, the VM should reboot into a functioning headless
system.

### Linode VM maintenance

At this point, I clone this repository on the remote and I use `nixos-rebuild`
to apply changes the system:

```shell
sudo nixos-rebuild switch --flake .
```

## macOS/Darwin

>[!WARNING]
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

```shell
nix run nix-darwin -- switch --flake .
```

If there are any errors, follow the error message (e.g. some folders may need
permissions changed, etc…). That's it.

### `nix-darwin` maintenance

Once `nix-darwin` is installed, successive incremental changes are applied with
`darwin-rebuild`:

```shell
darwin-rebuild switch --flake .
```
