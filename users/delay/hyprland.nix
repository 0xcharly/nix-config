{
  inputs,
  inputs',
  lib,
  pkgs,
  ...
} @ args:
{
  imports = [
    inputs.hyprland.homeManagerModules.default
    inputs.hyprpanel.homeManagerModules.hyprpanel
  ];
}
// (let
  inherit (config.modules.usrenv) isLinuxWaylandDesktop;

  config =
    if args ? osConfig
    then args.osConfig
    else args.config;

  dpiScale = 1.25;
  cursorSize = 32;

  hyprlandSessionVariables = {};
  waylandSessionVariables = {
    NIXOS_OZONE_WL = 1;

    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";

    # Automatically set by UWSM.
    # XDG_CURRENT_DESKTOP = "Hyprland";
    # XDG_SESSION_DESKTOP = "Hyprland";
    # XDG_SESSION_TYPE = "wayland";

    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_SCALE_FACTOR = dpiScale;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORMTHEME = "qt5ct";

    GDK_BACKEND = "wayland,x11,*";
    GDK_DPI_SCALE = dpiScale;
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
          path = pkgs.writeText "catppuccin-obsidian.rasi" (builtins.readFile ./rofi.rasi);
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

    xdg.configFile = {
      "electron-flags.conf".text = lib.concatStringsSep " " ["--ozone-platform-hint=auto"];

      # For Hyprland UWSM enviroment settings
      "uwsm/env".text = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (key: value: "export ${key}=${builtins.toString value}") waylandSessionVariables
      );
      "uwsm/env-hyprland".text = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (key: value: "export ${key}=${builtins.toString value}") hyprlandSessionVariables
      );
    };

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.variables = ["--all"];
      # Set the Hyprland and XDPH packages to null to use the ones from the NixOS module
      # TODO(25.05): Enable this when the HM module is updated to use the new packages.
      # package = null;
      # portalPackage = null;
      # Managed by UWSM.
      systemd.enable = false;
      # Layout plugin.
      plugins = [inputs'.hy3.packages.hy3];
      # Hyprland configuration.
      settings = {
        # Open apps on startup.
        exec-once = [
          "uwsm app -- systemctl --user enable --now hyprpanel.service"
          "uwsm app -- systemctl --user enable --now hyprpaper.service"
          "[workspace 1] uwsm app -- ${lib.getExe args.config.programs.firefox.finalPackage}"
          # "[workspace 2] uwsm app -- ${lib.getExe args.config.programs.chromium.package}"
          "[workspace 3] uwsm app -- ${lib.getExe pkgs.ghostty}"
          # "[workspace 8] uwsm app -- ${lib.getExe pkgs.obsidian}"
          # "[workspace 9] uwsm app -- ${lib.getExe pkgs.tidal-hifi}"
        ];

        # Monitor scaling.
        monitor = "DP-3, 3840x2160@239.991Hz, 0x0, ${builtins.toString dpiScale}";
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
          border_size = 2;
          gaps_in = 4;
          gaps_out = 8;
          "col.active_border" = "$red $maroon $peach $yellow $green $teal $sky $sapphire $blue $lavender 45deg";
          "col.inactive_border" = "$overlay0";
        };
        decoration.rounding = 8;
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
            "borderangle, 1,    500, user,     loop"
            "fade,        1,    1,   user"
            "fadeDim,     1,    1,   user_dim"
            "layers,      1,    1,   user,     popin 70%"
            "windows,     1,    1,   user,     popin 70%"
            "workspaces,  1,    2,   user,     slidefade 10%"
          ];
        };
        # Keyboard bindings.
        bind = [
          "SUPER,       Return, exec, uwsm app -- ${lib.getExe pkgs.ghostty}"
          "SUPER,       Space,  exec, pkill rofi || ${lib.getExe args.config.programs.rofi.finalPackage} -show combi  -run-command \"uwsm app -- {cmd}\" -calc-command \"echo -n '{result}' | ${pkgs.wl-clipboard}/bin/wl-copy\""
          "SUPER SHIFT, X,      killactive, "
          "SUPER SHIFT, Q,      exec, uwsm app -- loginctl terminate-session \"$XDG_SESSION_ID\""
          "SUPER,       V,      togglefloating, "
          "SUPER CTRL,  C,      exec, uwsm app -- ${lib.getExe pkgs.wl-color-picker}"
          "SUPER,       P,      exec, uwsm app -- ${lib.getExe pkgs.grimblast} --notify edit area"
          "SUPER SHIFT, P,      exec, uwsm app -- ${lib.getExe pkgs.grimblast} --notify edit active"
          "SUPER CTRL,  P,      exec, uwsm app -- ${lib.getExe pkgs.grimblast} --notify edit screen"

          "SUPER,       d, hy3:makegroup,   h"
          "SUPER,       s, hy3:makegroup,   v"
          "SUPER,       z, hy3:makegroup,   tab"
          "SUPER,       a, hy3:changefocus, raise"
          "SUPER SHIFT, a, hy3:changefocus, lower"
          "SUPER,       e, hy3:expand,      expand"
          "SUPER SHIFT, e, hy3:expand,      base"
          "SUPER,       r, hy3:changegroup, opposite"

          "SUPER,       left,   hy3:movefocus, l"
          "SUPER,       right,  hy3:movefocus, r"
          "SUPER,       up,     hy3:movefocus, u"
          "SUPER,       down,   hy3:movefocus, d"

          "SUPER CTRL,  left,   hy3:movefocus, l, visible, nowrap"
          "SUPER CTRL,  right,  hy3:movefocus, r, visible, nowrap"
          "SUPER CTRL,  up,     hy3:movefocus, u, visible, nowrap"
          "SUPER CTRL,  down,   hy3:movefocus, d, visible, nowrap"

          "SUPER SHIFT, left,   hy3:movewindow, l, once"
          "SUPER SHIFT, right,  hy3:movewindow, r, once"
          "SUPER SHIFT, up,     hy3:movewindow, u, once"
          "SUPER SHIFT, down,   hy3:movewindow, d, once"

          "SUPER CTRL SHIFT,  left,   hy3:movefocus, l, once, visible"
          "SUPER CTRL SHIFT,  right,  hy3:movefocus, r, once, visible"
          "SUPER CTRL SHIFT,  up,     hy3:movefocus, u, once, visible"
          "SUPER CTRL SHIFT,  down,   hy3:movefocus, d, once, visible"

          "ALT,         1,      workspace, 1"
          "ALT,         2,      workspace, 2"
          "ALT,         3,      workspace, 3"
          "ALT,         4,      workspace, 4"
          "ALT,         5,      workspace, 5"
          "ALT,         6,      workspace, 6"
          "ALT,         7,      workspace, 7"
          "ALT,         8,      workspace, 8"
          "ALT,         9,      workspace, 9"
          "ALT,         0,      workspace, 10"
          "ALT SHIFT,   1,      hy3:movetoworkspace, 1"
          "ALT SHIFT,   2,      hy3:movetoworkspace, 2"
          "ALT SHIFT,   3,      hy3:movetoworkspace, 3"
          "ALT SHIFT,   4,      hy3:movetoworkspace, 4"
          "ALT SHIFT,   5,      hy3:movetoworkspace, 5"
          "ALT SHIFT,   6,      hy3:movetoworkspace, 6"
          "ALT SHIFT,   7,      hy3:movetoworkspace, 7"
          "ALT SHIFT,   8,      hy3:movetoworkspace, 8"
          "ALT SHIFT,   9,      hy3:movetoworkspace, 9"
          "ALT SHIFT,   0,      hy3:movetoworkspace, 10"

          "SUPER CTRL,  1,      hy3:focustab, 1"
          "SUPER CTRL,  2,      hy3:focustab, 2"
          "SUPER CTRL,  3,      hy3:focustab, 3"
          "SUPER CTRL,  4,      hy3:focustab, 4"
          "SUPER CTRL,  5,      hy3:focustab, 5"
          "SUPER CTRL,  6,      hy3:focustab, 6"
          "SUPER CTRL,  7,      hy3:focustab, 7"
          "SUPER CTRL,  8,      hy3:focustab, 8"
          "SUPER CTRL,  9,      hy3:focustab, 9"
          "SUPER CTRL,  0,      hy3:focustab, 10"
        ];
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
          "float, class:^org.pulseaudio.pavucontrol$, title: ^Volume Control$"
          "float, class:^(firefox|zen)$, title: ^Picture-in-Picture$"
          "pin, class:^(firefox|zen)$, title: ^Picture-in-Picture$"
          "move 2550 56, class:^(firefox|zen)$, title: ^Picture-in-Picture$"
          "size 512 288, class:^(firefox|zen)$, title: ^Picture-in-Picture$"
        ];
      };
    };

    # Wallpaper.
    services.hyprpaper = {
      enable = true;
      settings = let
        wallpaper = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/Jas-SinghFSU/Configs/refs/heads/master/Wallpapers/RosePine/astronaut_fields.jpg";
          hash = "sha256-oWnTS7bSjSscl+m/Kr1W3L/6gsQlv8qtSkjtupvBnJU=";
        };
        wallpaper_path = builtins.toString wallpaper;
      in {
        ipc = true;
        splash = false;
        preload = [wallpaper_path];
        wallpaper = [", ${wallpaper_path}"];
      };
    };

    programs.hyprpanel = {
      enable = true;

      # Add '/nix/store/.../hyprpanel' to your Hyprland config 'exec-once'.
      hyprland.enable = true;

      # Fix the overwrite issue with HyprPanel.
      overwrite.enable = true;

      # Import a theme from './themes/*.json'.
      # Default: ""
      theme = "catppuccin_mocha";

      # Override the final config with an arbitrary set.
      # Useful for overriding colors in your selected theme.
      # Default: {}
      override = {
        # theme.bar.menus.text = "#123ABC";
      };

      # Configure bar layouts for monitors. See 'https://hyprpanel.com/configuration/panel.html'.
      layout = {
        "bar.layouts" = {
          "0" = {
            left = ["dashboard" "workspaces"];
            middle = ["media"];
            right = ["volume" "clock" "notifications"];
          };
        };
      };

      # Configure and theme almost all options from the GUI.
      # See 'https://hyprpanel.com/configuration/settings.html'.
      settings = {
        theme.bar.buttons.enableBorders = true;
        theme.bar.floating = true;
        theme.bar.margin_bottom = "0em";
        theme.bar.margin_sides = "3px";
        theme.bar.margin_top = "8px";
        bar.clock.format = "%Y年 %m月 %Od日 (%a) %R";
        bar.clock.showIcon = false;
        bar.launcher.autoDetectIcon = true;
        bar.media.show_active_only = true;
        bar.workspaces.monitorSpecific = false;
        bar.workspaces.show_numbered = false;
        bar.workspaces.spacing = 0.6;
        bar.workspaces.workspaces = 10;

        terminal = lib.getExe pkgs.ghostty;

        menus.clock.time.hideSeconds = true;
        menus.clock.time.military = true;
        menus.clock.weather.key = config.age.secrets."services/weather-api.key".path;
        menus.clock.weather.location = "Tokyo";
        menus.clock.weather.unit = "metric";
        menus.dashboard.directories.enabled = false;
        menus.dashboard.shortcuts.left.shortcut1.command = "firefox";
        menus.dashboard.shortcuts.left.shortcut1.icon = "󰈹";
        menus.dashboard.shortcuts.left.shortcut2.command = "tidal-hifi";
        menus.dashboard.shortcuts.left.shortcut2.icon = "󰎇";

        theme.bar.buttons.clock.spacing = "0em";
        theme.bar.buttons.padding_x = "0.6rem";
        theme.bar.buttons.padding_y = "0.15rem";
        theme.bar.buttons.radius = "0.6em";
        theme.bar.buttons.workspaces.pill.active_width = "8em";
        theme.bar.buttons.y_margins = "0em";
        theme.bar.dropdownGap = "50px";
        theme.bar.outer_spacing = "0em";
        theme.bar.transparent = true;
        theme.font = {
          name = "Recursive Sans Casual Static";
          size = "16px";
        };
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
