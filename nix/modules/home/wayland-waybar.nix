{
  config,
  lib,
  pkgs,
  ...
}: {
  options.node.wayland.waybar = with lib; {
    output = mkOption {
      type = types.listOf types.str;
      example = ''["DP-3"]'';
      description = ''
        The monitors on which to display the status bar.
      '';
    };

    extra-modules-right = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ''["battery"]'';
      description = ''
        List of extra modules to prepend to waybar's right-side widget list.
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
          modules-right = cfg.extra-modules-right ++ ["wireplumber" "clock"];

          "hyprland/workspaces" = {
            format = "{name}";
            on-click = "activate";
            sort-by-number = true;
            on-scroll-up = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch workspace e+1";
            on-scroll-down = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch workspace e-1";
          };
          battery = {
            states = {
              warning = 20;
              critical = 10;
            };
            events = {
              on-discharging-warning = "notify-send -u normal 'Battery below 20%'";
              on-discharging-critical = "notify-send -u critical 'Battery below 10%'";
              on-charging-100 = "notify-send -u normal 'Battery Full'";
            };
            format = "{icon} {capacity}%";
            format-icons = [" " " " " " " " " "];
          };
          clock = {
            format = "{:%Od日 %R}";
            tooltip-format = "<tt>{calendar}</tt>";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#f5e0dc'><b>{}</b></span>";
                days = "<span color='#e1e8f4'><b>{}</b></span>";
                weeks = "<span color='#9fcdfe'><b>W{}</b></span>";
                weekdays = "<span color='#8fa3bb'><b>{}</b></span>";
                today = "<span color='#cab4f4'><b><u>{}</u></b></span>";
              };
            };
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
          positiveBg = "#243c2e";
          positiveFg = "#aff3c0";
          warningBg = "#433027";
          warningFg = "#fec49a";
          urgentBg = "#41262e";
          urgentFg = "#fe9fa9";
        };
      in
        pkgs.replaceVars ./waybar-style.css colors;
    };
  };
}
