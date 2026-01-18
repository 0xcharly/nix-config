{
  flake,
  inputs,
  ...
}:
{
  config,
  lib,
  ...
}:
let
  cfg = config.node.services.atuin;
in
{
  imports = [ inputs.nix-config-colorscheme.modules.home.atuin ];

  options.node.services.atuin = with lib; {
    enableSync = mkEnableOption "Enable syncing shell history via the atuin service";
  };

  config.programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = lib.mkIf cfg.enableSync {
      auto_sync = true;
      key_path = config.age.secrets."services/atuin.key".path;
      session_path = config.age.secrets."services/atuin.session".path;
      sync_frequency = "5m";
      sync_address = "https://${flake.lib.facts.services.atuin.domain}";
    };
  };
}
