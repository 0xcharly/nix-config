# NixOS System Configurations

This repository contains my NixOS system configurations.

This repository was originally forked from [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config), and then adapted to my needs and hosts.

I don't claim to be an expert at Nix or NixOS and have yet to hone my knowledge of the overall ecosystem.

> [!WARNING]
>
> **Don't do this without reading the source.**
>
> This repository's configuration is heavily tuned to my preferences. If you blindly run this, your systems may be changed in ways that you don't want.

## Secrets management

Most secrets are encrypted and stored in a private repository.

Secrets for provisioning are stored in a self-hosted VaultWarden instance, and fetched via the bitwarden CLI.

After provisioning, a host needs to first login to the custom instance:

```sh
bw config server <url>
bw login
```
