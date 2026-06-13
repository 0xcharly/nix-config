{ inputs, ... }:
{
  flake.nixosModules.initrd-hoopsnake =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.hoopsnake.nixosModules.default ];

      options.node.boot.initrd.hoopsnake = with lib; {
        clientIdFile = mkOption {
          type = types.path;
          default =
            config.age.secrets."services/hoopsnake/${config.networking.hostName}/tailscale-client-id".path;
          description = ''
            The path to the file containing the Tailscale OpenID2 client ID.
          '';
        };
        clientSecretFile = mkOption {
          type = types.path;
          default =
            config.age.secrets."services/hoopsnake/${config.networking.hostName}/tailscale-client-secret".path;
          description = ''
            The path to the file containing the Tailscale OpenID2 client secret.
          '';
        };
        privateHostKeyFile = mkOption {
          type = types.path;
          default =
            config.age.secrets."services/hoopsnake/${config.networking.hostName}/ssh_host_ed25519_key".path;
          description = ''
            The path to the file containing the SSH private host key.
          '';
        };

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
          default = [ ];
          description = ''
            The list of network interface drivers to load at boot.

            NOTE: wireless interfaces are _not_ supported.

            Find drivers to load: `lspci -v | grep -iA8 'network\|ethernet'`.
          '';
        };
      };

      config.boot =
        let
          cfg = config.node.boot.initrd.hoopsnake;
        in
        {
          # https://nixos.org/manual/nixos/stable/release-notes#sec-release-26.05-highlights
          # If you use LUKS disk encryption […]. If you need to disable the
          # timeout before you can boot into the system, pass
          # systemd.default_device_timeout_sec=infinity on the kernel command
          # line.
          #
          # It is an alternate solution to setting this flag on fileSystems."/"
          # instead:
          #     fileSystems."/".options = [ "x-systemd.device-timeout=infinity" ];
          #
          # If the above option doesn't work, try the one below.
          # kernelParams = [ "systemd.default_device_timeout_sec=infinity" ];

          initrd = {
            availableKernelModules = cfg.kernelModules;
            systemd.extraBin.ping = lib.getExe' pkgs.iputils "ping";

            network = {
              enable = true;
              hoopsnake = {
                enable = true;
                systemd-credentials = {
                  privateHostKey = {
                    file = cfg.privateHostKeyFile;
                    encrypted = false;
                  };

                  clientId = {
                    file = cfg.clientIdFile;
                    encrypted = false;
                  };
                  clientSecret = {
                    file = cfg.clientSecretFile;
                    encrypted = false;
                  };
                };
                ssh = {
                  authorizedKeysFile =
                    lib.concatStringsSep "\n" cfg.authorizedKeys |> pkgs.writeText "authorized_keys";
                  commandLine = [
                    "/bin/systemctl"
                    "default"
                  ];
                };
                tailscale = {
                  name = "${config.networking.hostName}-unlock";
                  tags = [ "tag:initrd" ];
                  preauthorized = true;
                };
              };
            };
          };
        };
    };
}
