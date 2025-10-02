{
  flake,
  inputs,
  ...
}: {
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.walker.homeManagerModules.default
    flake.modules.home.wayland-uwsm
  ];

  programs.walker = {
    enable = true;
    package = pkgs.walker;
    runAsService = true;

    config = {
      app_launch_prefix = "${config.node.wayland.uwsm-wrapper.prefix} ";
      close_when_open = true;
      terminal = lib.getExe config.programs.ghostty.package;
      timeout = 0;
      theme = "catppuccin-obsidian";

      activation_mode.labels = "aoeuhtns";
      builtins = {
        calc.enabled = true;

        translation = {
          enabled = true;
          provider = "googlefree";
        };

        # Custom search engines.
        websearch = {
          entries = [
            {
              name = "GitHub";
              # TODO(25.11): https://github.com/abenz1267/walker/issues/332
              url = "https://github.com/search?type=code&q=%TERM%";
              prefix = "@cs ";
            }
            {
              name = "Home Manager Options";
              url = "https://home-manager-options.extranix.com/?query=%TERM%";
              prefix = "@hm ";
            }
            {
              name = "NixOS Options";
              url = "https://search.nixos.org/options?query=%TERM%";
              prefix = "@no ";
            }
            {
              name = "NixOS Packages";
              url = "https://search.nixos.org/packages?query=%TERM%";
              prefix = "@np ";
            }
            {
              name = "NixOS Wiki";
              url = "https://wiki.nixos.org/w/index.php?search=%TERM%";
              prefix = "@nw ";
            }
          ];
        };
      };
    };
  };

  xdg.configFile = {
    "walker/themes/catppuccin-obsidian.toml".source = ./walker-layout.toml;
    "walker/themes/catppuccin-obsidian.css".source = let
      colors = {
        accentFg = "#9fcdfe";
        accentBg = "#203147";
        cursorFg = "#cab4f4";
        cursorBg = "#312b41";
        normalBg = "#192029";
        normalFg = "#8fa3bb";
        urgentBg = "#41262e";
        urgentFg = "#fe9fa9";
      };
    in
      pkgs.replaceVars ./walker-style.css colors;
  };
}
