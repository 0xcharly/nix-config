{
  config,
  lib,
  ...
}: let
  cfg = config.services.healthchecks;
in
  lib.mkIf config.modules.system.services.serve.healthchecks {
    services.healthchecks = {
      enable = true;
      settings = {
        SITE_NAME = "Healthchecks";
        SITE_ROOT = "https://healthchecks.qyrnl.com";

        REGISTRATION_OPEN = false;
        SECRET_KEY_FILE = config.age.secrets."services/healthchecks-secret-key".path;

        # EMAIL_HOST = "localhost";
        # EMAIL_PORT = "25";
        # EMAIL_USE_TLS = "False";

        EMAIL_HOST = "smtp.gmail.com";
        EMAIL_PORT = "587";
        EMAIL_HOST_USER = "jcd.delay@gmail.com";
        EMAIL_HOST_PASSWORD_FILE = config.age.secrets."services/msmtp-gmail".path;

        DEFAULT_FROM_EMAIL = "noreply@healthchecks.qyrnl.com";
      };
    };

    users.users.${cfg.user}.extraGroups = ["sendmail"];
  }
