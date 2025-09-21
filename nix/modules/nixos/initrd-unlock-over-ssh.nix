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

    kernelParams = mkOption {
      type = types.listOf types.str;
      default = ["ip=::::${config.networking.hostName}-initrd::dhcp"];
      description = ''
        The kernel params to use to configure the initrd stage network.
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

    inherit (cfg) kernelParams;
  };
}
