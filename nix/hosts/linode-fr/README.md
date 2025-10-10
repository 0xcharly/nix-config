# EU Linode instance

## Installation

(Derived from https://www.linode.com/docs/guides/install-nixos-on-linode/)

The Linode images use 2 disks: - /dev/sda: System - /dev/sdb: Swap

For installation, the ISO image is written to the Swap partition. This partition
is overwritten during installation. On reboot, this partition is normally
mounted by the system as a swap.

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

1. If deploying on a Nanode (Linode 1Go), consider temporarily resizing the
   machine to at least a Shared Linode 2Go plan to improve performances and
   avoid OOM during system installation. Do this after creating the disk to
   facilitate the downsizing process post install.

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
