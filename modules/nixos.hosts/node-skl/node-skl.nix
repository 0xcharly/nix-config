{ self, inputs, ... }:
{
  my.hosts.node-skl = {
    stateVersion = "25.05";

    nixosModule =
      { lib, ... }:
      {
        imports = [
          self.nixosModules.colors-console

          inputs.nix-config-secrets.nixosModules.default
          inputs.nix-config-secrets.nixosModules.services-gatus-external-endpoints
          inputs.nix-config-secrets.nixosModules.services-hoopsnake-node-skl
          inputs.nix-config-secrets.nixosModules.services-tailscale

          self.nixosModules.profile-fs-btrfs-server-baremetal
          self.nixosModules.profile-hardware-server

          self.nixosModules.access-directory
          self.nixosModules.bootloader-systemd-boot
          self.nixosModules.hardware-cpu-intel
          self.nixosModules.hardware-gpu-intel
          self.nixosModules.initrd-hoopsnake
          self.nixosModules.nix
          self.nixosModules.nixpkgs
          self.nixosModules.programs-essentials
          self.nixosModules.programs-iotop
          self.nixosModules.programs-packages-common
          self.nixosModules.programs-secrets
          self.nixosModules.programs-sudo
          self.nixosModules.programs-terminfo
          self.nixosModules.programs-wakeonlan
          self.nixosModules.prometheus-exporters-node
          self.nixosModules.prometheus-exporters-smartctl
          self.nixosModules.services-fail2ban
          self.nixosModules.services-mullvad-exit-node-check
          self.nixosModules.services-openssh
          self.nixosModules.services-qbittorrent
          self.nixosModules.services-qui
          self.nixosModules.services-servarr
          self.nixosModules.services-tailscale
          self.nixosModules.system-common
        ];

        # System config
        node = {
          boot.initrd.hoopsnake.kernelModules = [ "e1000e" ];

          fs.btrfs.root = {
            disk = "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_512GB_S2GMNCAGB32083T";
            luksPasswordFile = "/tmp/root-disk-encryption.key";
            swapSize = "4G";
          };

          networking.tailscale = {
            enableSsh = true;
            exitNode = "jp-tyo-wg-001.mullvad.ts.net.";
          };
          services.mullvad-exit-node-check = {
            enable = true;
            killswitch = {
              units = [ "qbittorrent.service" ];
              mode = "gate";
            };
          };
          services.qbittorrent.enable = true;
          services.qui.enable = true;
          services.servarr.enable = true;
          users.delay.ssh.authorizeTailscaleInternalKey = true;
        };

        environment.persistence."/persist" = {
          files = [ "/var/lib/qui-session.secret" ]; # services-qui.nix — sessions survive
          directories = [
            "/var/lib/qBittorrent" # profileDir default (capital B!) — session/fastresume
            "/var/lib/radarr"
            "/var/lib/sonarr"
            "/var/lib/lidarr"
            "/var/lib/qui" # StateDirectory=qui, dedicated user (verified via systemctl cat)
            {
              # prowlarr: DynamicUser + StateDirectory (verified) — 0700 or
              # systemd refuses.
              directory = "/var/lib/private";
              mode = "0700";
            }
            "/srv" # torrents + media library
          ];
        };

        # /tmp stays on disk: a large release unpacking into RAM-backed tmpfs is
        # the one realistic memory-pressure scenario on this box. mkForce: any
        # future module flipping this must conflict loudly here, not win
        # silently.
        boot.tmp.useTmpfs = lib.mkForce false;

        boot.initrd.availableKernelModules = [
          "ahci"
          "nvme"
          "sd_mod"
          "usbhid"
          "xhci_pci"
        ];

        networking.interfaces.eno1.useDHCP = true;
      };

    users.delay.imports = with self.homeModules; [ profile-hardware-server ];
  };
}
