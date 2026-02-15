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
    wallpaper = {
      animate = mkEnableOption "Enable wallpaper animations";
    };
    modules = {
      power = mkEnableOption "Enable the power management module";
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
        settings.theme = {
          desktop.animateWallpaper = cfg.wallpaper.animate;
          hud.bar.power.enable = cfg.modules.power;
        };
      };
    };
}
