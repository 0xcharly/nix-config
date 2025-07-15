{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.modules.system.services.serve.vaultwarden {
  services.vaultwarden = {
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

  users.users.vaultwarden.extraGroups = ["sendmail"];
}
