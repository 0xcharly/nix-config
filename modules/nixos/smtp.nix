{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.smtp;
in {
  options.node.services.smtp.enable = lib.mkEnableOption "Whether to expose an SMTP service.";

  config = lib.mkIf cfg.enable {
    # services.nullmailer = {
    #   enable = config.modules.system.roles.services.smtp.enable;
    #   remotesFile = config.age.secrets."services/nullmailer-gmail".path;
    #   config = {
    #     allmailfrom = "mail@qyrnl.com";
    #     adminaddr = "mail+monitoring@qyrnl.com";
    #   };
    # };

    programs.msmtp = {
      enable = true;
      accounts.default = {
        auth = true;
        host = "smtp.gmail.com";
        port = 587;
        from = "mail@qyrnl.com";
        user = "jcd.delay@gmail.com";
        passwordeval = "cat ${config.age.secrets."services/msmtp-gmail".path}";
        tls = true;
        tls_starttls = true;
      };
    };

    # Creates the group `sendmail`.
    users.groups.sendmail = {};

    # Adds delay to group `sendmail`.
    users.users.delay.extraGroups = ["sendmail"];

    assertions = [
      {
        assertion = config.modules.services.serve.vaultwarden -> cfg.enable;
        message = "`system.services.serve.vaultwarden` requires SMTP";
      }
    ];
  };
}
