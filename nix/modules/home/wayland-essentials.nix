{
  config,
  lib,
  pkgs,
  ...
}: {
  options.node.wayland = with lib; {
    display.logicalResolution = {
      width = mkOption {
        type = types.int;
        description = ''
          The amount of pixel in a row. Should match `node.wayland.hyprland.monitor` values.
        '';
      };
      height = mkOption {
        type = types.int;
        description = ''
          The amount of pixel in a column. Should match `node.wayland.hyprland.monitor` values.
        '';
      };
    };

    pip = {
      margin = {
        x = mkOption {
          type = types.int;
          default = 16;
          description = ''
            The horizontal distance between the screen edge and the Picture-in-Picture window.

            The Picture-in-Picture window is positioned in the top-right corner of the screen.
          '';
        };
        y = mkOption {
          type = types.int;
          default = 16;
          description = ''
            The vertical distance between the screen edge and the Picture-in-Picture window.

            The Picture-in-Picture window is positioned in the top-right corner of the screen.
          '';
        };
      };
      width = mkOption {
        type = types.int;
        default = 640;
        description = ''
          The default width of the Picture-in-Picture window.
        '';
      };
      height = mkOption {
        type = types.int;
        default = 360;
        description = ''
          The default height of the Picture-in-Picture window.
        '';
      };
    };
  };

  config = {
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

          # Steam used `GDK_SCALE` before.
          STEAM_FORCE_DESKTOPUI_SCALING = 2;

          MOZ_ENABLE_WAYLAND = 1;
          _JAVA_AWT_WM_NONREPARENTING = 1;

          XCURSOR_THEME = config.home.pointerCursor.name;
          XCURSOR_SIZE = config.home.pointerCursor.size;
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
  };
}
