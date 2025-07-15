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

        REGISTRATION_OPEN = true;
        SECRET_KEY_FILE = config.age.secrets."services/healthchecks-secret-key".path;
      };
    };

    users.users.${cfg.user}.extraGroups = ["sendmail"];
  }
