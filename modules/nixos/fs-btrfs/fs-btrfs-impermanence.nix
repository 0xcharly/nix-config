{ inputs, ... }:
{
  flake.nixosModules.fs-btrfs-impermanence = {
    imports = [ inputs.impermanence.nixosModules.impermanence ];

    # Workstations already have this via programs-greetd-autologin.nix;
    # Linodes and node-skl flip here.
    boot.initrd.systemd.enable = true;

    # Wipe @root: restore the blank snapshot on every boot, before /sysroot
    # mounts.
    boot.initrd.systemd.services.rollback-root = {
      description = "Rollback btrfs @root to the blank snapshot";
      wantedBy = [ "initrd.target" ];
      after = [ "cryptsetup.target" ]; # /dev/mapper/crypted must exist
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /btrfs_tmp
        # Fail OPEN, not closed: for a wipe-on-boot mechanism on remote hosts,
        # "boot dirty and complain loudly" beats "drop to initrd emergency and
        # require Lish-console surgery". Skipping costs one boot of
        # impermanence purity; failing costs reachability.
        if ! mount -t btrfs -o subvol=/ /dev/mapper/crypted /btrfs_tmp; then
          echo "rollback-root: MOUNT FAILED — SKIPPING ROOT WIPE, booting previous root" >&2
          exit 0
        fi
        if [ ! -e /btrfs_tmp/@root-blank ]; then
          echo "rollback-root: @root-blank MISSING — SKIPPING ROOT WIPE, booting previous root" >&2
          umount /btrfs_tmp
          exit 0
        fi

        # systemd auto-creates nested subvolumes inside @root
        # (/var/lib/portables, /var/lib/machines); a subvolume containing
        # others cannot be deleted, so recurse or boot #3 fails.
        delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
          done
          btrfs subvolume delete "$1"
        }

        if [ -e /btrfs_tmp/@root ]; then
          delete_subvolume_recursively /btrfs_tmp/@root
        fi
        btrfs subvolume snapshot /btrfs_tmp/@root-blank /btrfs_tmp/@root
        umount /btrfs_tmp
      '';
    };

    environment.persistence."/persist" = {
      hideMounts = true;
      files = [ "/etc/machine-id" ];
      directories = [
        "/var/lib/nixos" # uid/gid maps
        "/var/lib/systemd" # timers Persistent=, random-seed, backlight
        "/var/lib/tailscale" # node identity — or the node re-registers and disrupts the mesh
        "/var/lib/fail2ban" # ban DB (all seven hosts import services-fail2ban)
        # scrub.status.<uuid>: `btrfs scrub status` history. Without it every
        # reboot resets the host to "never scrubbed" and blinds the scrub
        # textfile metrics until the next monthly scrub.
        "/var/lib/btrfs"
        "/var/log"
      ];
    };

    # Host key lives on /persist directly: available the moment /persist
    # mounts (neededForBoot), no bind-mount ordering hazard. agenix
    # identityPaths defaults to this path via services.openssh.hostKeys,
    # keeping secret decryption working.
    services.openssh.hostKeys = [
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    # TODO: Drop these two symlinks once Tailscale SSH is retired fleet-wide.
    #
    # Tailscale SSH terminates tailnet port-22 connections and presents the
    # host's OpenSSH key — but it reads it from the canonical /etc/ssh path,
    # not from sshd's configuration. Without this it falls back to its own
    # generated key and every pinned known-hosts entry mismatches. String
    # source (not a path literal): a direct symlink, nothing copied to the
    # store; /persist is neededForBoot so the target is valid from early boot.
    environment.etc."ssh/ssh_host_ed25519_key".source = "/persist/etc/ssh/ssh_host_ed25519_key";
    environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/persist/etc/ssh/ssh_host_ed25519_key.pub";
  };
}
