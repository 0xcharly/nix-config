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
    flake.modules.home.wayland-uwsm
    inputs.nix-config-colorscheme.modules.home.walker
  ];

  services.walker = {
    enable = true;
    package = pkgs.walker;
    systemd.enable = true;

    settings = {
      app_launch_prefix = "${config.node.wayland.uwsm-wrapper.prefix} ";
      close_when_open = true;
      terminal = lib.getExe config.programs.kitty.package;
      timeout = 0;

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
}
