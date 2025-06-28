{
  config,
  lib,
  pkgs,
  ...
}: let
  vaultwardenConfig = config.services.vaultwarden.config;
in
  lib.mkIf config.modules.system.services.serve.vaultwarden {
    services.vaultwarden = {
      enable = true;
      environmentFile = config.age.secrets."services/vaultwarden.env".path;
      config = {
        DOMAIN = "https://vault.qyrnl.com";
        PASSWORD_HINTS_ALLOWED = false;

        # Listen on localhost (IPv4) so Tailscale can access it.
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;

        # Send mail from nullmailer relay.
        SMTP_FROM = "vaultwarden@qyrnl.com";
        USE_SENDMAIL = true;
        SENDMAIL_COMMAND = lib.getExe pkgs.msmtp;
      };
    };

    users.users.vaultwarden.extraGroups = ["sendmail"];

    # TODO: use a reverse proxy instead (e.g. Caddy).
    # systemd.services = {
    #   tailscale-serve-vaultwarden = {
    #     description = "Tailscale Serve for Vaultwarden";
    #     wantedBy = ["multi-user.target"];
    #     after = ["network-online.target" "tailscaled.service"];
    #     requires = ["network-online.target" "tailscaled.service"];
    #
    #     serviceConfig = {
    #       Type = "oneshot";
    #       ExecStart = let
    #         tailscale-serve-vaultwarden = pkgs.writeShellApplication {
    #           name = "tailscale-serve-vaultwarden";
    #           runtimeInputs = with pkgs; [tailscale];
    #           text = ''
    #             tailscale serve --https=443 --set-path=/ off || true
    #             tailscale serve --https=443 --set-path=/ --bg ${toString vaultwardenConfig.ROCKET_PORT}
    #           '';
    #         };
    #       in
    #         lib.getExe tailscale-serve-vaultwarden;
    #       RemainAfterExit = true;
    #     };
    #   };
    # };
  }
