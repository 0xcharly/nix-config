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

Note that I usually full screen the VM so there isn't actually a window, and I
three-finger swipe or use other keyboard shortcuts to active that window.

## NixOS VM on macOS host

### NixOS VM setup

>[!NOTE]
>
> This setup guide will cover VMware Fusion because that is the hypervisor I use
> day to day.
> The original fork of this repository also supports UTM  and Parallels  but I'm
> not using that so removed the configurations to simplify maintenance. I've
> also removed the Windows support (VMware Workstation and Hyper-V).

Download the ISO from [NixOS downloads](https://nixos.org/download/#nixos-iso).
For Apple Silicon hardware, use the `aarch64` (64-bit ARM) images.

Create a VMware Fusion VM with the following settings. My configurations are
made for VMware Fusion so expect issues on other virtualization solutions
without minor changes.

* ISO: NixOS 23.11 or later.
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
the Makefile will install the OS. If you setup your VM to use SATA, this should
exist. If `/dev/nvme` or `/dev/vda` exists instead, you didn't configure the
disk properly. Note, these other block device types work fine, but you'll have
to modify the `bootstrap0-vm-aarch64.sh` to use the proper block device paths.

Also at this point, I recommend making a snapshot in case anything goes wrong,
or simply to quickly go back to a blank slate. I usually call this snapshot
"pre-bootstrap0".

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

Perform the initial bootstrap. This will install NixOS on the VM disk image but
will not setup any other configurations yet. This prepares the VM for any NixOS
customization:

```shell
make vm/bootstrap0
```

After the VM reboots, run the full bootstrap, this will finalize the NixOS
customization using this configuration:

```shell
make vm/bootstrap
```

You should have a functioning VM with graphical environment.

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
export NIXNAME=vm-aarch64
```

Perform the initial bootstrap. This will install NixOS on the VM disk image but
will not setup any other configurations yet. This prepares the VM for any NixOS
customization:

```shell
make vm/bootstrap0
```

After the VM reboots, run the full bootstrap, this will finalize the NixOS
customization using this configuration:

```shell
make vm/bootstrap
```

You should have a functioning headless system.

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
_some_ aspects of my macOS installation, too. This uses the
https://github.com/LnL7/nix-darwin project. I don't manage _everything_ with
Nix, for example I don't manage apps, some of my system settings, Homebrew, etc.
I plan to migrate some of those in time.

To utilize the Mac setup, first install Nix using some Nix installer.

I use the https://github.com/DeterminateSystems/nix-installer by Determinate
Systems.com. The point is just to get the `nix` CLI with flake support
installed.

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
