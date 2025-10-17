# NixOS System Configurations

This repository contains my NixOS system configurations.

This repository was originally forked from
[mitchellh/nixos-config](https://github.com/mitchellh/nixos-config), and then
adapted to my needs and hosts.

I don't claim to be an expert at Nix or NixOS and have yet to hone my knowledge
of the overall ecosystem.

> [!WARNING]
>
> **Don't do this without reading the source.**
> This repository's configuration is heavily tuned to my preferences. If you
> blindly run this, your system may be changed in ways that you don't want.
>
> Unlike NixOS, it is more troublesome to revert a the effect of nix-darwin,
> since there's no snapshot to restore to.
>
> Read the source!

## NixOS: Workstation

## NixOS: NAS

## NixOS: Linode VM

### Linode VM setup

// TODO

## macOS/Darwin

### `nix-darwin` setup

I share some of my Nix configurations with my Mac host and use Nix to manage
_most_ aspects of my macOS installation, too. This uses the
[nix-darwin](https://github.com/LnL7/nix-darwin) project. I don't manage
_everything_ with Nix yet, in particular I don't manage most of my GUI apps. I
plan to migrate some of those in time. My system settings, Homebrew, etc. are
however already managed by Nix.

To utilize the macOS setup, first install Nix using some Nix installer.

I use the [nix-installer](https://github.com/DeterminateSystems/nix-installer)
by Determinate Systems. The point is just to get the `nix` CLI with flake
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
just switch
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
> **This configuration is not properly tested**
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
just switch
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

## Nix cheatsheet

Some arbitrary collection of commands that have been useful in the past.

### Add input to registry

```sh
nix registry add <input> <url>
```

### Repair Nix store

```sh
nix-store --verify --repair
nix-store --gc
nix-collect-garbage -d
```

## Secrets management

Most secrets are encrypted and stored in a private repository.

Secrets for provisioning are stored in a self-hosted VaultWarden instance, and
fetched via the bitwarden CLI.

After provisioning, a host needs to first login to the custom instance:

```sh
bw config server <url>
bw login
```
