{
  config,
  lib,
  pkgs,
  ...
} @ args: let
  inherit ((lib.user.getUserConfig args).modules.usrenv) isLinuxWaylandDesktop;
in
  lib.mkIf isLinuxWaylandDesktop {
    services.swaync.enable = true;

    home = {
      packages = with pkgs; [
        swayimg # Image viewer
        wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
        wl-color-picker # GUI color picker
        wlr-randr # Utility to manage outputs of a Wayland compositor

        qt5.qtwayland
        qt6.qtwayland
      ];
    };

    programs.waybar = {
      enable = lib.mkDefault isLinuxWaylandDesktop;
      systemd.enable = lib.mkDefault config.programs.waybar.enable;
      settings = {
        mainBar = {
          layer = "bottom";
          position = "bottom";
          output = ["DP-3"];
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
        pkgs.replaceVars ./waybar/style.css colors;
    };

    xdg = {
      # For Wayland UWSM enviroment settings.
      configFile."uwsm/env".text = let
        waylandSessionVariables = {
          NIXOS_OZONE_WL = 1;
          # This forces the use of the Wayland backend for Electron, but we don't want
          # 1Password to use Wayland just yet because copy/paste doesn't work.
          # ELECTRON_OZONE_PLATFORM_HINT = "auto";

          CLUTTER_BACKEND = "wayland";
          SDL_VIDEODRIVER = "wayland";

          QT_AUTO_SCREEN_SCALE_FACTOR = 1;
          QT_QPA_PLATFORM = "wayland;xcb";
          # Should be managed automatically by the wayland compositor.
          # QT_SCALE_FACTOR = dpiScale;
          QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
          QT_QPA_PLATFORMTHEME = "gtk3";

          # Tells GTK (via GDK, its lower-level windowing layer) which windowing
          # system backend to use when running GTK applications.
          GDK_BACKEND = "wayland,x11,*";

          # Scales all UI elements (widgets, windows, etc.) by an _integer_ factor.
          # Coarse scaling that affects layout size. Commonly used to double or triple
          # the size of the UI on HiDPI screens.
          GDK_SCALE = 2;

          # Applies a fractional scaling factor to _text rendering_. It adjusts the
          # size of fonts without changing the layout size of other UI elements.
          GDK_DPI_SCALE = 1;

          MOZ_ENABLE_WAYLAND = 1;
          _JAVA_AWT_WM_NONREPARENTING = 1;

          XCURSOR_THEME = args.config.home.pointerCursor.name;
          XCURSOR_SIZE = args.config.home.pointerCursor.size;
        };

        create-env = envvars:
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (key: value: "export ${key}=${builtins.toString value}") envvars
          );
      in
        create-env waylandSessionVariables;

      mimeApps.defaultApplications = {
        "application/pdf" = ["zathura.desktop"];
        "image/jpeg" = ["swayimg"];
        "image/png" = ["swayimg"];
        "image/gif" = ["swayimg"];
        "image/webp" = ["swayimg"];
        "image/bmp" = ["swayimg"];
        "image/svg+xml" = ["swayimg"];
        "image/avif" = ["swayimg"];
        "image/heif" = ["swayimg"];
        "image/tiff" = ["swayimg"];
        "application/sixel" = ["swayimg"];
        "image/openexr" = ["swayimg"];
        "image/x-portable-anymap" = ["swayimg"];
        "image/tga" = ["swayimg"];
        "image/qoi" = ["swayimg"];
        "image/dicom" = ["swayimg"];
        "application/farbfeld" = ["swayimg"];
      };
    };
  }
