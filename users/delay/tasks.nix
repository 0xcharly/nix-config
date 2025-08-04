{
  lib,
  pkgs,
  ...
} @ args: let
  inherit ((lib.user.getUserConfig args).modules) flags;
  inherit ((lib.user.getUserConfig args).node) facts;
  cfg = flags.taskwarrior;
in {
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    colorTheme = "no-color";
    extraConfig =
      ''
        news.version=3.4.2
      ''
      + lib.optionalString cfg.enableSync ''
        include ${args.osConfig.age.secrets."services/taskwarrior-sync.key".path}
        sync.server.url=${cfg.syncAddress}
        sync.server.client_id=${facts.taskwarrior.userUUID}

        # https://github.com/GothenburgBitFactory/taskwarrior/blob/2e3badbf991e726ba0f0c4b5bb6b243ea2dcdfc3/doc/man/taskrc.5.in#L489
        recurrence=${
          if facts.taskwarrior.primaryClient
          then "1"
          else "0"
        }
      '';
  };

  home.packages = [pkgs.taskwarrior-tui];
}
