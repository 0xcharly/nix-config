{
  config,
  lib,
  ...
}:
{
  options.node.services.msmtp = with lib; {
    enable = mkEnableOption "Spin up a msmtp relay";

    allowUsers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of user accounts to enable msmtp for.
      '';
    };
  };

  config =
    let
      cfg = config.node.services.msmtp;
    in
    {
      programs.msmtp = {
        inherit (cfg) enable;
        accounts =
          let
            mkProtonAccount = user: {
              auth = true;
              host = "smtp.protonmail.ch";
              port = 587;
              from = user;
              user = user;
              passwordeval = "cat ${config.age.secrets."services/msmtp-${user}.token".path}";
              tls = true;
              tls_starttls = true;
            };
          in
          {
            default = mkProtonAccount "mail@qyrnl.com";
            vaultwarden = mkProtonAccount "vaultwarden@qyrnl.com";
          };
      };

      users = lib.mkIf cfg.enable {
        groups.sendmail = { };
        users =
          let
            addToSendmailGroup = user: {
              ${user}.extraGroups = [ "sendmail" ];
            };
          in
          lib.mergeAttrsList (builtins.map addToSendmailGroup ([ "delay" ] ++ cfg.allowUsers));
      };
    };
}
