{flake, ...}: {
  config,
  lib,
  ...
}: let
  cfg = config.node.services.atuin;
in {
  options.node.services.atuin = with lib; {
    enableSync = mkEnableOption "Enable syncing shell history via the atuin service";
  };

  config.programs.atuin = {
    enable = true;
    flags = ["--disable-up-arrow"];
    settings = lib.mkIf cfg.enableSync {
      auto_sync = true;
      key_path = config.age.secrets."services/atuin.key".path;
      session_path = config.age.secrets."services/atuin.session".path;
      sync_frequency = "5m";
      sync_address = flake.lib.facts.services.atuin.url;
    };
  };
}
