{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.node.services.vaultwarden;
in {
  options.node.services.vaultwarden.enable = lib.mkEnableOption "Whether to spin up a Vaultwarden server.";

  config = {
    services = {
      vaultwarden = lib.mkIf cfg.enable {
        enable = true;
        environmentFile = config.age.secrets."services/vaultwarden.env".path;
        config = {
          DOMAIN = "https://vault.qyrnl.com";
          PASSWORD_HINTS_ALLOWED = false;
          SIGNUPS_ALLOWED = false; # Disable registration.

          # Listen on localhost (IPv4) so Tailscale can access it.
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;

          # Send mail from nullmailer relay.
          SMTP_FROM = "vaultwarden@qyrnl.com";
          USE_SENDMAIL = true;
          SENDMAIL_COMMAND = lib.getExe pkgs.msmtp;
        };
      };

      caddy.virtualHosts = lib.mkIf config.node.services.reverseProxy.enable {
        "vault.qyrnl.com".extraConfig = ''
          import ts_host
          reverse_proxy bowmore.qyrnl.com:${toString config.services.vaultwarden.config.ROCKET_PORT}
        '';
      };

      gatus.settings.endpoints = [
        (lib.fn.mkHttpServiceEndpoint "vaultwarden" "vault.qyrnl.com")
      ];
    };

    users = lib.mkIf cfg.enable {
      users.vaultwarden.extraGroups = ["sendmail"];
    };
  };
}
