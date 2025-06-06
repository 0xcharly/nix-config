{
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.hm.getUserConfig args).modules.usrenv) isLinuxWaylandDesktop;

  waylandSessionVariables = {
    NIXOS_OZONE_WL = 1;
    # This forces the use of the Wayland backend for Electron, but we don't want
    # 1Password to use Wayland just yet because copy/paste doesn't work.
    # ELECTRON_OZONE_PLATFORM_HINT = "auto";

    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";

    # Automatically set by UWSM.
    # XDG_CURRENT_DESKTOP = "Hyprland";
    # XDG_SESSION_DESKTOP = "Hyprland";
    # XDG_SESSION_TYPE = "wayland";

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

    # IMPORTANT: Keep in sync with ./linux-desktop.nix.
    XCURSOR_THEME = "BreezeX-RosePine-Linux";
    XCURSOR_SIZE = args.config.home.pointerCursor.size;
  };
in
  lib.mkIf isLinuxWaylandDesktop {
    home = {
      packages = with pkgs; [
        # Screenshot toolchain.
        grim # Fullscreen and window capture
        slurp # Region capture
        grimblast # High-level screenshot utility
        swappy # Annotation tool

        hyprpicker # Command line color picker
        swayimg # Image viewer
        wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
        wl-color-picker # GUI color picker
        wlr-randr # Utility to manage outputs of a Wayland compositor

        qt5.qtwayland
        qt6.qtwayland
      ];
      sessionVariables = {
        GRIMBLAST_EDITOR = "${lib.getExe pkgs.swappy} -f";
      };
    };

    xdg = {
      configFile = let
        create-env = envvars:
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (key: value: "export ${key}=${builtins.toString value}") envvars
          );
        chromiumFlags = ''
          --ozone-platform=wayland
          --ozone-platform-hint=auto
          --enable-features=UseOzonePlatform,VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo
          --enable-features=NativeNotifications
        '';
      in {
        "chrome-flags.conf".text = chromiumFlags;
        "chromium-flags.conf".text = chromiumFlags;
        "electron-flags.conf".text = chromiumFlags;
        "electron12-flags.conf".text = chromiumFlags;
        "electron32-flags.conf".text = chromiumFlags;

        # For Hyprland UWSM enviroment settings
        "uwsm/env".text = create-env waylandSessionVariables;
      };

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

    programs = {
      rofi = {
        enable = true;
        package = pkgs.rofi-wayland;
        plugins = [
          (pkgs.rofi-calc.override {rofi-unwrapped = pkgs.rofi-wayland-unwrapped;})
        ];
        theme = {
          "@theme" = builtins.path {
            name = "catppuccin-obsidian.rasi";
            path = pkgs.writeText "catppuccin-obsidian.rasi" (builtins.readFile ./rofi/catppuccin-obsidian.rasi);
          };
        };
      };
    };
  }
