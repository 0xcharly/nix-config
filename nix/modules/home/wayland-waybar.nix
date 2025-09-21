{
  config,
  lib,
  pkgs,
  ...
}: {
  options.node.wayland = with lib; {
    waybar.output = mkOption {
      type = types.listOf types.str;
      example = ''["DP-3"]'';
      description = ''
        The monitors on which to display the status bar.
      '';
    };
  };

  config = {
    programs.waybar = let
      cfg = config.node.wayland.waybar;
    in {
      enable = true;
      systemd.enable = lib.mkDefault config.programs.waybar.enable;
      settings = {
        mainBar = {
          inherit (cfg) output;
          layer = "bottom";
          position = "bottom";
          margin-bottom = 4;
          margin-left = 4;
          margin-right = 4;
          spacing = 8;
          modules-left = ["hyprland/workspaces"];
          modules-center = [];
          modules-right = ["wireplumber" "clock"];

          "hyprland/workspaces" = {
            format = "{name}";
            on-click = "activate";
            sort-by-number = true;
            on-scroll-up = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch workspace e+1";
            on-scroll-down = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch workspace e-1";
          };
          clock = {
            format = "{:%Od日 %R}";
          };
          wireplumber = {
            format = "{icon} {volume}%";
            format-muted = "  {volume}%";
            format-icons = [" " " " " "];
            on-click-middle = "${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          };
        };
      };
      style = let
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
        pkgs.replaceVars ./waybar-style.css colors;
    };
  };
}
