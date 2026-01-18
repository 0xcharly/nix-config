{ inputs, ... }:
{
  config,
  lib,
  ...
}:
{
  imports = [
    inputs.nix-config-shell.homeManagerModules.default

    inputs.nix-config-colorscheme.modules.home.arcshell
  ];

  options.node.wayland.arcshell = with lib; {
    modules = {
      powerManagement = mkEnableOption "Enable the power management module";
    };
  };

  config =
    let
      cfg = config.node.wayland.arcshell;
    in
    {
      programs.arcshell = {
        enable = true;
        systemd.enable = true;
        settings.theme.hud.widgets.powerManagement.enable = cfg.modules.powerManagement;
      };
    };
}
