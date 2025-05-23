{
  inputs,
  lib,
  pkgs,
  usrlib,
  ...
} @ args:
{
  imports = [inputs.hyprpanel.homeManagerModules.hyprpanel];
}
// (let
  config = usrlib.hm.getUserConfig args;
  inherit (config.modules.stdenv) isNixOS;
  inherit (config.modules.usrenv) isCorpManaged isLinuxWaylandDesktop;

  dpiScale = 2;
  cursorSize = 32;

  uwsm-wrapper = cmd: "${lib.getExe pkgs.uwsm} app -- ${cmd}";
  map-workspaces = mapFn:
    builtins.map (x:
      mapFn (toString x) (
        if x == 0
        then "10"
        else (toString x)
      )) (builtins.genList (x: x) 10);
  map-movements = mapFn:
    lib.attrsets.mapAttrsToList mapFn {
      "left" = "l";
      "right" = "r";
      "up" = "u";
      "down" = "d";
    };

  hyprlandSessionVariables = {};
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
    # QT_SCALE_FACTOR = dpiScale;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORMTHEME = "qt5ct";

    GDK_BACKEND = "wayland,x11,*";
    # Setting GDK_DPI_SCALE changes the scale of Firefox (i.e. overscales it).
    # GDK_DPI_SCALE = dpiScale;
    # Setting GDK_SCALE changes the scale of 1Password.
    GDK_SCALE = dpiScale;

    MOZ_ENABLE_WAYLAND = 1;
    _JAVA_AWT_WM_NONREPARENTING = 1;

    # IMPORTANT: Keep in sync with ./desktop.nix.
    XCURSOR_THEME = "BreezeX-RosePine-Linux";
    XCURSOR_SIZE = cursorSize;
  };
in
  lib.mkIf isLinuxWaylandDesktop {
    programs.rofi = {
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

    home.packages = with pkgs; [
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

    xdg.configFile = let
      create-env = envvars:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (key: value: "export ${key}=${builtins.toString value}") envvars
        );
      electronFlags = ''
        --ozone-platform=wayland
        --ozone-platform-hint=auto
        --enable-features=UseOzonePlatform,VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo
      '';
    in {
      "electron-flags.conf".text = electronFlags;
      "electron12-flags.conf".text = electronFlags;
      "electron32-flags.conf".text = electronFlags;

      # For Hyprland UWSM enviroment settings
      "uwsm/env".text = create-env waylandSessionVariables;
      "uwsm/env-hyprland".text = create-env hyprlandSessionVariables;
    };

    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-hyprland
    ];

    wayland.windowManager.hyprland = {
      enable = true;

      # Set the Hyprland and XDPH packages to null to use the ones from the NixOS module
      # TODO(25.05): Enable this when the HM module is updated to use the new packages.
      # package = if isNixOS then null else pkgs.hyprland;
      # portalPackage = if isNixOS then null else pkgs.xdg-desktop-portal-hyprland;

      systemd = {
        enable = false; # Managed by UWSM.
        variables = ["--all"];
      };

      # Layout plugin.
      plugins = [pkgs.hyprlandPlugins.hy3];

      # Hyprland configuration.
      settings = {
        # TODO(25.05): Uncomment.
        # ecosystem = {
        #   no_update_news = true;
        #   no_donation_nag = true;
        # };

        # Open apps on startup.
        exec-once = lib.mkIf (!isCorpManaged) [
          (uwsm-wrapper "systemctl --user enable --now hyprpanel.service")
          (uwsm-wrapper "systemctl --user enable --now hyprpaper.service")
          "[workspace 1] ${uwsm-wrapper (lib.getExe pkgs.google-chrome)}"
          # "[workspace 1] ${uwsm-wrapper (lib.getExe args.config.programs.firefox.finalPackage)}"
          "[workspace 3] ${uwsm-wrapper (lib.getExe pkgs.ghostty)}"
          # "[workspace 8] ${uwsm-wrapper (lib.getExe pkgs.obsidian)}"
          # "[workspace 9] ${uwsm-wrapper (lib.getExe pkgs.tidal-hifi)}"
        ];

        # Monitor scaling.
        monitor = lib.mkDefault "DP-3, 3840x2160@239.991Hz, 0x0, ${builtins.toString dpiScale}";
        # Properly scale X11 applications (e.g. 1Password) by unscaling XWayland.
        xwayland.force_zero_scaling = true;

        # Keyboard input setup.
        input = {
          kb_options = "ctrl:nocaps";
          kb_layout = "us";
          kb_variant = "mac";
          repeat_delay = 200;
          repeat_rate = 60;
        };
        general = {
          layout = "hy3"; # Requires the hy3 plugin.
          border_size = 1;
          gaps_in = 2;
          gaps_out = 4;
          "col.active_border" = "$red $maroon $peach $yellow $green $teal $sky $sapphire $blue $lavender 45deg";
          "col.inactive_border" = "$overlay0";
        };
        decoration.rounding = 4;
        plugin.hy3 = {
          tabs = {
            height = 8;
            padding = 8;
            rounding = 3;
            render_text = false;
            "col.active" = "$blue";
            "col.inactive" = "$overlay0";
            "col.urgent" = "$peach";
          };
        };
        bezier = [
          "user, 0.6, 0.5, 0.1, 1"
          "user_dim, 0.3, 0.4, 0.6, 0.7"
        ];
        animations = {
          enabled = true;
          animation = [
            # https://wiki.hyprland.org/Configuring/Animations/#animation-tree
            # name, on/off, speed (100ms increments), curve, style
            # borderangle loop requires Hyprland to push new frame at the
            # monitor's refresh rate, which puts stress on CPU/GPU. Don't do
            # this on a laptop.
            "border,      1,    1,   user"
            # "borderangle, 1,    500, user,     loop"
            "fade,        1,    1,   user"
            "fadeDim,     1,    1,   user_dim"
            "layers,      1,    1,   user,     popin 70%"
            "windows,     1,    1,   user,     popin 70%"
            "workspaces,  1,    2,   user,     slidefade 10%"
          ];
        };
        # Keyboard bindings.
        bind =
          [
            "SUPER,       Return, exec, ${uwsm-wrapper (lib.getExe pkgs.ghostty)}"
            "SUPER,       Space,  exec, pkill rofi || ${uwsm-wrapper (lib.getExe args.config.programs.rofi.finalPackage)} -show combi  -run-command \"${uwsm-wrapper "{cmd}"}\" -calc-command \"echo -n '{result}' | ${pkgs.wl-clipboard}/bin/wl-copy\""
            "SUPER SHIFT, X,      killactive, "
            "SUPER SHIFT, Q,      exec, ${uwsm-wrapper "loginctl terminate-session \"$XDG_SESSION_ID\""}"
            "SUPER SHIFT, L,      exec, ${uwsm-wrapper (lib.getExe pkgs.hyprlock)}"
            "SUPER,       V,      togglefloating, "
            "SUPER,       F,      fullscreen, "
            "SUPER CTRL,  C,      exec, ${uwsm-wrapper (lib.getExe pkgs.wl-color-picker)}"
            "SUPER,       P,      exec, ${uwsm-wrapper (lib.getExe pkgs.grimblast)} --notify edit area"
            "SUPER SHIFT, P,      exec, ${uwsm-wrapper (lib.getExe pkgs.grimblast)} --notify edit active"
            "SUPER CTRL,  P,      exec, ${uwsm-wrapper (lib.getExe pkgs.grimblast)} --notify edit screen"

            "SUPER,       D,      hy3:makegroup,   h"
            "SUPER,       S,      hy3:makegroup,   v"
            "SUPER,       Z,      hy3:makegroup,   tab"
            "SUPER,       A,      hy3:changefocus, raise"
            "SUPER SHIFT, A,      hy3:changefocus, lower"
            "SUPER,       E,      hy3:expand,      expand"
            "SUPER SHIFT, E,      hy3:expand,      base"
            "SUPER,       R,      hy3:changegroup, opposite"
          ]
          ++ (map-movements (dir: key: "SUPER, ${dir}, hy3:movefocus, ${key}, wrap"))
          ++ (map-movements (dir: key: "SUPER SHIFT, ${dir}, hy3:movewindow, ${key}, once"))
          ++ (map-workspaces (no: repr: "ALT, ${no}, workspace, ${repr}"))
          ++ (map-workspaces (no: repr: "ALT SHIFT, ${no}, hy3:movetoworkspace, ${repr}"));
        # Mouse bindings.
        bindm = [
          "SUPER, mouse:272, movewindow" # Left mouse button.
          "SUPER, mouse:273, resizewindow" # Right mouse button.
        ];
        # Window rules.
        windowrulev2 = [
          # "workspace 1, class:^firefox$"
          # "workspace 2, class:^chromium-browser$"
          # "workspace 5, class:^1Password$"
          "float, class:^thunar$, title:^File Operation Progress$"
          "float, class:^org.pulseaudio.pavucontrol$, title:^Volume Control$"
          # Chrome's Picture-in-Picture.
          "float, class:^$, title:^Picture in picture$"
          "pin, class:^$, title:^Picture in picture$"
          "move 1403 35, class:^$, title:^Picture in picture$"
          "size 512 288, class:^$, title:^Picture in picture$"
          "keepaspectratio, class:^$, title:^Picture in picture$"
          # Firefox's Picture-in-Picture.
          "float, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
          "pin, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
          "move 2554 38, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
          "size 512 288, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
          "keepaspectratio, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
        ];
      };
    };

    # Wallpaper.
    services.hyprpaper = {
      enable = true;
      settings = let
        wallpaper = pkgs.fetchurl {
          # url = "https://4kwallpapers.com/images/wallpapers/duality-doorway-3840x2160-22094.jpg";
          # hash = "sha256-i8ER2prXODSNX3V1S1jZbStWxYFldDbAbj17OyHqJQA=";
          # url = "https://4kwallpapers.com/images/wallpapers/palm-trees-3840x2160-18170.jpg";
          # hash = "sha256-4A0wSYYTiK8aZwBDDxsYRJokJGC/Zu6dlVSfQtyo8Wg=";
          # url = "https://4kwallpapers.com/images/wallpapers/biker-helmet-neon-3840x2160-15476.jpg";
          # hash = "sha256-wZuzkAsp2T8Ay3SE2OagbA1+q+V4gJKmZQ2wRWOkIL8=";
          # url = "https://4kwallpapers.com/images/wallpapers/drippy-smiley-3840x2160-11481.png";
          # hash = "sha256-ngDPUMj0FW3kGBydFOOZuqpQICwVdh6OAz5wne1tAx8=";
          # url = "https://4kwallpapers.com/images/wallpapers/houston-quotes-3840x2160-11107.png";
          # hash = "sha256-obz2keeSe3f3v1X9xzBytfUi0RSjQLxrHbR2mIYFr0A=";
          # url = "https://4kwallpapers.com/images/wallpapers/red-heart-pixel-art-3840x2160-15194.png";
          # hash = "sha256-G+m6164/x4M8An/ZnqFLgqe82nbIsCfa+J5JsyeAnjU=";
          # url = "https://4kwallpapers.com/images/wallpapers/jelly-bears-gummy-3840x2160-11036.jpg";
          # hash = "sha256-sG4+YYLgbHqGKbRWFZWiHk98ximJhqJeysoToyxHlN0=";
          # url = "https://4kwallpapers.com/images/wallpapers/tree-seasons-black-3840x2160-11116.png";
          # hash = "sha256-H/OBDRf1g1g9ss48MorAs1PnY/6vwHdwZBI/TW6a4sE=";
          # url = "https://4kwallpapers.com/images/wallpapers/daft-punk-helmet-dark-background-minimal-art-3840x2160-6112.jpg";
          # hash = "sha256-MWSFB0FWiojMefl4qrAxDVgZohcUbL72QR/Is/EvdEE=";
          # url = "https://4kwallpapers.com/images/wallpapers/light-night-forest-winter-foggy-dark-3840x2160-5431.jpg";
          # hash = "sha256-HXU0axf5/gW5yfYamHlaPJNKfYkrpOziNYB74xauUa8=";
          # url = "https://4kwallpapers.com/images/wallpapers/paper-art-origami-panoply-triangle-geometrical-multicolor-3840x2160-4724.jpg";
          # hash = "sha256-3hZSHw+FhEQ0qro1Ju2L4aJtTh3iegLrqyfrlAgaYZU=";
          # url = "https://4kwallpapers.com/images/wallpapers/kitsune-fox-spirit-3840x2160-10986.jpg";
          # hash = "sha256-osz9snMW+grNy/Gy5bj3wf8+DDfGAaFgCZOF76fFiJI=";
          # url = "https://4kwallpapers.com/images/wallpapers/halloween-pumpkins-3840x2160-11101.jpg";
          # hash = "sha256-IcGNQsG4zidsqL1InsC/VZacDg3Q9WWzbyX/CCU2M3A=";
          url = "https://4kwallpapers.com/images/wallpapers/rainbow-coffee-3840x2160-11110.png";
          hash = "sha256-WSb9B/xPSwv5djkYZ46g7B8r6hujboeIqD2DmEN2KtY=";
          # url = "https://4kwallpapers.com/images/wallpapers/gargantua-black-3840x2160-9621.jpg";
          # hash = "sha256-FprHpbr4I/17Jem0Ik98ilsjUqvCAOii2gDKwhKbAdY=";
        };
        wallpaper_path = builtins.toString wallpaper;
      in {
        ipc = true;
        splash = false;
        preload = [wallpaper_path];
        wallpaper = [", ${wallpaper_path}"];
      };
    };

    programs.hyprlock = {
      enable = true;
      settings = {
        general = [
          {
            disable_loading_bar = true;
            grace = 0;
            hide_cursor = true;
            no_fade_in = false;
          }
        ];

        background = [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            size = "512, 64";
            position = "0, 0";
            dots_center = true;
            dots_size = 0.2;
            dots_spacing = 0.4;
            fade_on_empty = false;
            font_color = "rgba(225, 232, 244, 1)";
            inner_color = "rgba(29, 37, 48, 1)";
            outer_color = "rgba(21, 27, 35, 1)";
            check_color = "rgba(137, 180, 250, 1)";
            fail_color = "rgba(254, 154, 164, 1)";
            outline_thickness = 2;
            placeholder_text = "<i><span foreground=\"##bac2deff\">Password…</span></i>";
            shadow_passes = 2;
            shadow_color = "rgba(21, 27, 35, 1)";
          }
        ];
      };
    };

    services.hypridle = {
      enable = true;
      settings = let
        hyprctl = "${pkgs.hyprland}/bin/hyprctl";
        hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
        loginctl = "${pkgs.systemd}/bin/loginctl";
        systemctl = "${pkgs.systemd}/bin/systemctl";

        # Avoid starting multiple hyprlock instances.
        lock = "${pkgs.procps}/bin/pidof ${hyprlock} || ${hyprlock}";
      in {
        general = {
          lock_cmd = lock;
          unlock_cmd = "pkill - USR1 ${hyprlock}";

          before_sleep_cmd = "${loginctl} lock-session"; # lock before suspend.
          after_sleep_cmd = "${hyprctl} dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
        };

        listener = [
          {
            timeout = 600; # 10 minutes.
            on-timeout = lock;
          }
          {
            timeout = 900; # 15 minutes.
            on-timeout = "${hyprctl} dispatch dpms off";
            on-resume = "${hyprctl} dispatch dpms on";
          }
          {
            timeout = 3600; # 1 hour.
            on-timeout = "${systemctl} suspend";
          }
        ];
      };
    };

    programs.hyprpanel = {
      enable = true;

      # Add '/nix/store/.../hyprpanel' to your Hyprland config 'exec-once'.
      hyprland.enable = true;

      # Fix the overwrite issue with HyprPanel.
      overwrite.enable = true;

      # Configure and theme almost all options from the GUI.
      # Configure bar layouts for monitors. See 'https://hyprpanel.com/configuration/panel.html'.
      # See 'https://hyprpanel.com/configuration/settings.html'.
      settings = {
        layout = {
          "bar.layouts" = {
            "0" = {
              left = ["dashboard" "workspaces"];
              middle = ["media"];
              right = ["volume" "clock" "notifications"];
            };
          };
        };
        # Import a theme from './themes/*.json'.
        # Default: ""
        theme.name = "catppuccin_mocha";
        theme.bar.buttons.enableBorders = false;
        theme.bar.floating = true;
        theme.bar.margin_bottom = "0em";
        theme.bar.margin_sides = "0em";
        theme.bar.margin_top = "5px";
        bar.clock.format = "%Y年 %m月 %Od日 (%a) %R";
        bar.clock.showIcon = false;
        bar.launcher.autoDetectIcon = true;
        bar.media.show_active_only = true;
        bar.media.truncation_size = 100;
        bar.workspaces.monitorSpecific = false;
        bar.workspaces.showWsIcons = true;
        bar.workspaces.spacing = 0.2;
        bar.workspaces.numbered_active_indicator = "highlight";
        bar.workspaces.workspaceMask = true;
        bar.workspaces.workspaces = 1;

        terminal = lib.getExe pkgs.ghostty;

        menus.clock.time.hideSeconds = true;
        menus.clock.time.military = true;
        menus.clock.weather = lib.mkIf isNixOS {
          key = args.osConfig.age.secrets."services/weather-api.key".path;
          location = "Tokyo";
          unit = "metric";
        };
        menus.dashboard.controls.enabled = false;
        menus.dashboard.directories.enabled = false;
        menus.dashboard.stats.enabled = false;
        menus.dashboard.shortcuts.left.shortcut1.command = "firefox";
        menus.dashboard.shortcuts.left.shortcut1.icon = "󰈹";
        menus.dashboard.shortcuts.left.shortcut1.tooltip = "Firefox";
        menus.dashboard.shortcuts.left.shortcut2.command = "tidal-hifi";
        menus.dashboard.shortcuts.left.shortcut2.icon = "󰎇";
        menus.dashboard.shortcuts.left.shortcut2.tooltip = "Tidal";
        menus.dashboard.shortcuts.left.shortcut3.command = "chromium";
        menus.dashboard.shortcuts.left.shortcut3.icon = "";
        menus.dashboard.shortcuts.left.shortcut3.tooltip = "Chromium";

        theme.bar.buttons.borderSize = "0px";
        theme.bar.buttons.clock.spacing = "0em";
        theme.bar.buttons.padding_x = "8px";
        theme.bar.buttons.padding_y = "1px";
        theme.bar.buttons.radius = "8px";
        theme.bar.buttons.workspaces.fontSize = "1.2em";
        theme.bar.buttons.workspaces.numbered_active_highlight_border = "0.3em";
        theme.bar.buttons.workspaces.numbered_active_highlight_padding = "0.4em";
        theme.bar.buttons.workspaces.numbered_inactive_padding = "0.4em";
        theme.bar.buttons.y_margins = "0em";
        theme.bar.dropdownGap = "28px";
        theme.bar.outer_spacing = "0em";
        theme.bar.transparent = true;
        theme.font = {
          name = "Recursive Sans Casual Static";
          size = "12px";
        };
      };

      # Override the final config with an arbitrary set.
      override =
        lib.attrsets.mergeAttrsList (
          map-workspaces (no: repr: {"bar.workspaces.workspaceIconMap.${repr}" = no;})
        )
        // {
          "theme.bar.buttons.battery.background" = "#11181c";
          "theme.bar.buttons.bluetooth.background" = "#11181c";
          "theme.bar.buttons.clock.background" = "#11181c";
          "theme.bar.buttons.clock.text" = "#8fa3bb";
          "theme.bar.buttons.dashboard.background" = "#11181c";
          "theme.bar.buttons.dashboard.border" = "#95b7ef";
          "theme.bar.buttons.dashboard.icon" = "#95b7ef";
          "theme.bar.buttons.media.background" = "#11181c";
          "theme.bar.buttons.media.icon" = "#95b7ef";
          "theme.bar.buttons.media.text" = "#8fa3bb";
          "theme.bar.buttons.network.background" = "#11181c";
          "theme.bar.buttons.notifications.background" = "#11181c";
          "theme.bar.buttons.notifications.icon" = "#95b7ef";
          "theme.bar.buttons.systray.background" = "#11181c";
          "theme.bar.buttons.volume.background" = "#11181c";
          "theme.bar.buttons.volume.icon" = "#95b7ef";
          "theme.bar.buttons.volume.text" = "#8fa3bb";
          "theme.bar.buttons.windowtitle.background" = "#11181c";
          "theme.bar.buttons.workspaces.active" = "#203147";
          "theme.bar.buttons.workspaces.available" = "#8fa3bb";
          "theme.bar.buttons.workspaces.background" = "#11181c";
          "theme.bar.buttons.workspaces.border" = "#95b7ef";
          "theme.bar.buttons.workspaces.hover" = "#203147";
          "theme.bar.buttons.workspaces.numbered_active_highlighted_text_color" = "#9fcdfe";
          "theme.bar.buttons.workspaces.occupied" = "#bac2de";
          "theme.bar.menus.menu.notifications.height" = "48em";
        };
    };

    home.sessionVariables = {
      GRIMBLAST_EDITOR = "${lib.getExe pkgs.swappy} -f";
    };

    xdg.mimeApps.defaultApplications = {
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
  })
