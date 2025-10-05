{flake, ...}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.node.services.tasks;
in {
  options.node.services.tasks = with lib; {
    enableSync = mkEnableOption "Enable syncing tasks via the taskwarrior service";
    isPrimaryClient = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether this host is the primary host interacting with the taskwarrior
        service.
      '';
    };
  };

  config = {
    home.packages = [pkgs.taskwarrior-tui];

    programs.taskwarrior = {
      enable = true;
      package = pkgs.taskwarrior3;
      colorTheme = "no-color";
      extraConfig =
        ''
          news.version=3.4.2
        ''
        + lib.optionalString cfg.enableSync ''
          include ${config.age.secrets."services/taskwarrior-sync.key".path}
          sync.server.url=https://${flake.lib.facts.services.taskwarrior.domain}
          sync.server.client_id=${flake.lib.facts.services.taskwarrior.user-uuid}

          # https://github.com/GothenburgBitFactory/taskwarrior/blob/2e3badbf991e726ba0f0c4b5bb6b243ea2dcdfc3/doc/man/taskrc.5.in#L489
          recurrence=${
            if cfg.isPrimaryClient
            then "1"
            else "0"
          }
        '';
    };
  };
}
