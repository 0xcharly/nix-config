{flake, ...}: {
  config,
  lib,
  pkgs,
  ...
}: {
  options.node.services.vaultwarden = with lib; {
    enable = mkEnableOption "Spin up a Vaultwarden service";
  };

  config = let
    cfg = config.node.services.vaultwarden;
    inherit (flake.lib) facts;
  in {
    node = lib.mkIf cfg.enable {
      fs.zfs.zpool.root.datadirs = {
        vaultwarden = {
          owner = "vaultwarden";
          group = "vaultwarden";
          mode = "0700";
        };
      };
      services.msmtp.allowUsers = ["vaultwarden"];
    };

    services = {
      vaultwarden = {
        inherit (cfg) enable;
        backupDir = "/tank/delay/vault";
        environmentFile = config.age.secrets."services/vaultwarden.env".path;
        config = {
          DOMAIN = "https://${facts.services.vaultwarden.domain}";
          PASSWORD_HINTS_ALLOWED = false;
          SIGNUPS_ALLOWED = false; # Disable registration.

          ROCKET_ADDRESS = "0.0.0.0";
          ROCKET_PORT = facts.services.vaultwarden.port;

          SMTP_FROM = "vaultwarden@qyrnl.com";
          USE_SENDMAIL = true;
          # Send mail from msmtp relay.
          SENDMAIL_COMMAND = flake.lib.builders.mkShellApplication pkgs {
            name = "vaultwarden-sendmail";
            runtimeInputs = with pkgs; [msmtp];
            text = ''
              msmtp -a vaultwarden "$@"
            '';
          };
        };
      };
    };

    assertions = [
      {
        assertion = cfg.enable -> config.node.services.msmtp.enable;
        message = "Vaultwarden requires SMTP";
      }
    ];
  };
}
