{
  config,
  lib,
  pkgs,
  ...
} @ args: let
  inherit ((lib.user.getUserConfig args).modules.usrenv) isLinuxWaylandDesktop;
in
  lib.mkIf isLinuxWaylandDesktop {
    wayland.windowManager.sway = {
      enable = true;

      # SwayFX for slightly more eye candy.
      package = config.lib.nixGL.wrap pkgs.swayfx;
      # TODO(25.11): maybe no longer required?
      # https://github.com/nix-community/home-manager/issues/5379
      checkConfig = false; # Required for swayfx.

      config = {
        modifier = "Mod4";
        terminal = pkgs.ghostty;
        defaultWorkspace = "workspace number 1";
        fonts = {
          names = ["Recursive Sans Casual Static"];
          size = 12.0;
        };
        output = {
          DP-3 = {
            mode = "3840x2160@239.991Hz";
            scale = "1.25";
            bg = "#0b1215 solid_color";
          };
        };
        input = {
          "type:keyboard" = {
            repeat_delay = "200";
            repeat_rate = "60";
          };
          "*" = {
            xkb_options = "ctrl:nocaps";
            xkb_layout = "us";
            xkb_variant = "mac";
          };
        };

        window = {
          border = 1;
          titlebar = false;
          hideEdgeBorders = "smart_no_gaps";

          commands = [
            {
              criteria = {
                title = "^Picture in picture$";
                app_id = "";
              };
              command = "floating enable, sticky enable; move absolute position 2455 4";
            }
          ];
        };

        floating = {
          border = 1;
          titlebar = false;
        };

        gaps = {
          outer = 0;
          inner = 8;
          smartBorders = "on";
          smartGaps = true;
        };

        colors = {
          focused = {
            border = "#9fcdfe";
            background = "#203147";
            text = "#9fcdfe";
            indicator = "#2e9ef4";
            childBorder = "#9fcdfe";
          };

          focusedInactive = {
            border = "#333333";
            background = "#5f676a";
            text = "#ffffff";
            indicator = "#484e50";
            childBorder = "#5f676a";
          };

          unfocused = {
            border = "#1d2938";
            background = "#1d2530";
            text = "#bac2de";
            indicator = "#292d2e";
            childBorder = "#1d2938";
          };

          urgent = {
            border = "#2f343a";
            background = "#900000";
            text = "#ffffff";
            indicator = "#900000";
            childBorder = "#900000";
          };

          placeholder = {
            border = "#000000";
            background = "#0c0c0c";
            text = "#ffffff";
            indicator = "#000000";
            childBorder = "#0c0c0c";
          };
        };

        keybindings = let
          modifier = config.wayland.windowManager.sway.config.modifier;

          # uwsm-wrapper = cmd: "${lib.getExe pkgs.uwsm} app -- ${cmd}";
          # `app2unit --` is a faster alternative to `uwsm app --` (shell implementation
          # over Python).
          uwsm-wrapper = cmd: "${lib.getExe pkgs.app2unit} -- ${cmd}";
        in
          lib.mkOptionDefault {
            # Terminal.
            "${modifier}+Return" = "exec ${uwsm-wrapper (lib.getExe pkgs.ghostty)}";
            # Application launcher.
            "${modifier}+space" = "exec ${uwsm-wrapper (lib.getExe config.programs.walker.package)}";
            # Color picker.
            "${modifier}+Ctrl+c" = "exec ${uwsm-wrapper (lib.getExe pkgs.wl-color-picker)}";
            # Screenshot tool.
            "${modifier}+p" = "exec ${uwsm-wrapper (lib.getExe pkgs.sway-contrib.grimshot)} --notify save area";
            "${modifier}+Shift+p" = "exec ${uwsm-wrapper (lib.getExe pkgs.sway-contrib.grimshot)} --notify save active";
            "${modifier}+Ctrl+p" = "exec ${uwsm-wrapper (lib.getExe pkgs.sway-contrib.grimshot)} --notify save screen";

            # Spaces: numbers 1..9 + 0
            "${modifier}+1" = "workspace number 1";
            "${modifier}+2" = "workspace number 2";
            "${modifier}+3" = "workspace number 3";
            "${modifier}+4" = "workspace number 4";
            "${modifier}+5" = "workspace number 5";
            "${modifier}+6" = "workspace number 6";
            "${modifier}+7" = "workspace number 7";
            "${modifier}+8" = "workspace number 8";
            "${modifier}+9" = "workspace number 9";
            "${modifier}+0" = "workspace number 10";

            "${modifier}+Shift+1" = "move container to workspace number 1";
            "${modifier}+Shift+2" = "move container to workspace number 2";
            "${modifier}+Shift+3" = "move container to workspace number 3";
            "${modifier}+Shift+4" = "move container to workspace number 4";
            "${modifier}+Shift+5" = "move container to workspace number 5";
            "${modifier}+Shift+6" = "move container to workspace number 6";
            "${modifier}+Shift+7" = "move container to workspace number 7";
            "${modifier}+Shift+8" = "move container to workspace number 8";
            "${modifier}+Shift+9" = "move container to workspace number 9";
            "${modifier}+Shift+0" = "move container to workspace number 10";

            # Change focus with arrow keys.
            "${modifier}+Left" = "focus left";
            "${modifier}+Down" = "focus down";
            "${modifier}+Up" = "focus up";
            "${modifier}+Right" = "focus right";

            # Move windows with arrow keys.
            "${modifier}+Shift+Left" = "move left";
            "${modifier}+Shift+Down" = "move down";
            "${modifier}+Shift+Up" = "move up";
            "${modifier}+Shift+Right" = "move right";

            # Toggle tiling / floating.
            "${modifier}+v" = "floating toggle";

            # Kill focused window.
            "${modifier}+Shift+x" = "kill";
            # Restart i3 in-place.
            "${modifier}+Shift+r" = "restart";
            # Reload configuration.
            "${modifier}+Shift+c" = "reload";
            # Exit i3.
            "${modifier}+Shift+q" = "exit";
          };

        modes = {
          resize = {
            Down = "resize grow height 10 px";
            Escape = "mode default";
            Left = "resize shrink width 10 px";
            Return = "mode default";
            Right = "resize grow width 10 px";
            Up = "resize shrink height 10 px";
          };
        };

        bars = []; # Remove default `swaybar` config.
      };
      extraConfig = ''
        tiling_drag enable

        # SwayFX options.
        corner_radius 2
      '';
    };

    xdg.configFile = let
      sway-wrapped = pkgs.writeShellScriptBin "sway" (
        lib.getExe config.wayland.windowManager.sway.package
      );
      sway-uwsm = pkgs.writeShellScriptBin "sway-uwsm" ''
        ${lib.getExe pkgs.uwsm} start -S -F -- ${lib.getExe sway-wrapped}
      '';
    in {
      "sessions/sway".source = lib.getExe sway-wrapped;
      "sessions/sway-uwsm".source = lib.getExe sway-uwsm;
    };
  }
