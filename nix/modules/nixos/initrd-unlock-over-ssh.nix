{
  config,
  lib,
  ...
}: {
  options.node.boot.initrd.ssh-unlock = with lib; {
    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7f2u02SzpNnfOspwNMkj4nnZnjGjbg6KSDAbcUP49J remote-unlock"
      ];
      description = ''
        The SSH public keys accepted to unlock the system.
      '';
    };

    kernelModules = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        The list of network interface drivers to load at boot.

        NOTE: wireless interfaces are _not_ supported.

        Find drivers to load: `lspci -v | grep -iA8 'network\|ethernet'`.
      '';
    };
  };

  config.boot = let
    cfg = config.node.boot.initrd.ssh-unlock;
  in {
    initrd = {
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          shell = "/bin/cryptsetup-askpass";
          inherit (cfg) authorizedKeys;
          hostKeys = ["/etc/ssh/ssh_host_ed25519_key-initrd"];
        };
      };
      secrets."/etc/ssh/ssh_host_ed25519_key-initrd" = "/etc/ssh/ssh_host_ed25519_key-initrd";
      availableKernelModules = cfg.kernelModules;
    };

    kernelParams = ["ip=192.168.1.231::192.168.1.1:255.255.255.0:${config.networking.hostName}-initrd:enp197s0:off"];
    # kernelParams = ["ip=::::${config.networking.hostName}-initrd::dhcp"];
  };
}
