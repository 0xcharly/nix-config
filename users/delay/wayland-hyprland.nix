{
  config,
  inputs,
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.hm.getUserConfig args).modules.usrenv) isCorpManaged isLinuxWaylandDesktop;

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
in {
  imports = [inputs.hyprpanel.homeManagerModules.hyprpanel];

  wayland.windowManager.hyprland = let
    uwsm-wrapper = cmd: "${lib.getExe pkgs.uwsm} app -- ${cmd}";
  in {
    # Don't bother with Hyprland on corp machines.
    enable = lib.mkDefault (isLinuxWaylandDesktop && !isCorpManaged);

    # Set the Hyprland and XDPH packages to null to use the ones from the NixOS module.
    package = null;
    portalPackage = null;

    # Managed by UWSM.
    systemd.enable = false;

    # Layout plugin.
    plugins = with pkgs.hyprlandPlugins; [hy3];

    # Hyprland configuration.
    settings = {
      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      # Open apps on startup.
      exec-once = [
        (uwsm-wrapper "systemctl --user enable --now hyprpanel.service")
        (uwsm-wrapper "systemctl --user enable --now hyprpaper.service")
        "[workspace 1] ${uwsm-wrapper (lib.getExe pkgs.google-chrome)}"
        "[workspace 3] ${uwsm-wrapper (lib.getExe pkgs.ghostty)}"
      ];

      # Monitor scaling.
      monitor = lib.mkDefault "DP-3, 3840x2160@239.991Hz, 0x0, 1.25";
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
          "workspaces,  0,    2,   user,     slidefade 10%"
        ];
      };
      # Keyboard bindings.
      bind =
        [
          "SUPER,       Return, exec, ${uwsm-wrapper (lib.getExe pkgs.ghostty)}"
          "SUPER,       Space,  exec, pkill rofi || ${uwsm-wrapper (lib.getExe config.programs.rofi.finalPackage)} -show combi  -run-command \"${uwsm-wrapper "{cmd}"}\" -calc-command \"echo -n '{result}' | ${pkgs.wl-clipboard}/bin/wl-copy\""
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
        "move 2554 35, class:^$, title:^Picture in picture$"
        "size 512 288, class:^$, title:^Picture in picture$"
        "keepaspectratio, class:^$, title:^Picture in picture$"
        # Firefox's Picture-in-Picture.
        "float, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
        "pin, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
        "move 2554 35, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
        "size 512 288, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
        "keepaspectratio, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
      ];
    };
  };

  # Wallpaper.
  services.hyprpaper = {
    enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
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

  programs = {
    hyprlock = {
      enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
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

    hyprpanel = {
      enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;

      # Add '/nix/store/.../hyprpanel' to your Hyprland config 'exec-once'.
      hyprland.enable = true;

      # Fix the overwrite issue with HyprPanel.
      overwrite.enable = true;

      # Configure and theme almost all options from the GUI.
      # Configure bar layouts for monitors. See 'https://hyprpanel.com/configuration/panel.html'.
      # See 'https://hyprpanel.com/configuration/settings.html'.
      settings = {
        scalingPriority = "hyprland";

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
        theme = {
          name = "catppuccin_mocha";
          font = {
            name = "Recursive Sans Casual Static";
            size = "12px";
          };
          bar = {
            dropdownGap = "28px";
            floating = true;
            margin_bottom = "0em";
            margin_sides = "0em";
            margin_top = "5px";
            outer_spacing = "0em";
            transparent = true;

            buttons = {
              borderSize = "0px";
              clock.spacing = "0em";
              enableBorders = false;
              padding_x = "8px";
              padding_y = "1px";
              radius = "8px";
              y_margins = "0em";
              workspaces = {
                fontSize = "1.2em";
                numbered_active_highlight_border = "0.3em";
                numbered_active_highlight_padding = "0.4em";
                numbered_inactive_padding = "0.4em";
              };
            };
          };
        };
        bar = {
          clock = {
            format = "%Y年 %m月 %Od日 (%a) %R";
            showIcon = false;
          };
          launcher.autoDetectIcon = true;
          media = {
            show_active_only = true;
            truncation_size = 100;
          };
          workspaces = {
            monitorSpecific = false;
            showWsIcons = true;
            spacing = 0.2;
            numbered_active_indicator = "highlight";
            workspaceMask = true;
            workspaces = 1;
          };
        };

        terminal = lib.getExe pkgs.ghostty;

        menus = {
          clock = {
            time = {
              hideSeconds = true;
              military = true;
            };
            weather = {
              key = args.osConfig.age.secrets."services/weather-api.key".path;
              location = "Tokyo";
              unit = "metric";
            };
          };
          dashboard = {
            controls.enabled = false;
            directories.enabled = false;
            stats.enabled = false;
            shortcuts.left = {
              shortcut1 = {
                command = "firefox";
                icon = "󰈹";
                tooltip = "Firefox";
              };
              shortcut2 = {
                command = "tidal-hifi";
                icon = "󰎇";
                tooltip = "Tidal";
              };
              shortcut3 = {
                command = "google-chrome";
                icon = "";
                tooltip = "Google Chrome";
              };
            };
          };
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
  };

  services.hypridle = {
    enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
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
}
