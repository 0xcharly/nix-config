{
  config,
  lib,
  pkgs,
  ...
} @ args: let
  inherit ((lib.user.getUserConfig args).modules) flags;
  inherit ((lib.user.getUserConfig args).modules.usrenv) isCorpManaged isLinuxWaylandDesktop;

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
      decoration.rounding = 8;
      misc = {
        background_color = "0x0b1215";
        disable_hyprland_logo = true;
        force_default_wallpaper = 0;
      };
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
          "SUPER,       Space,  exec, pkill rofi || ${uwsm-wrapper (lib.getExe config.programs.rofi.finalPackage)} -show combi  -run-command \"${uwsm-wrapper "{cmd}"}\" -calc-command \"echo -n '{result}' | ${lib.getExe' pkgs.wl-clipboard "wl-copy"}\""
          "SUPER SHIFT, X,      killactive, "
          "SUPER SHIFT, Q,      exec, ${uwsm-wrapper "loginctl terminate-session \"$XDG_SESSION_ID\""}"
          "SUPER SHIFT, L,      exec, ${uwsm-wrapper (lib.getExe pkgs.hyprlock)}"
          "SUPER,       V,      togglefloating, "
          "SUPER,       F,      fullscreen, "
          "SUPER CTRL,  C,      exec, ${uwsm-wrapper (lib.getExe pkgs.wl-color-picker)}"
          "SUPER,       P,      exec, ${uwsm-wrapper (lib.getExe pkgs.grimblast)} edit area"
          "SUPER SHIFT, P,      exec, ${uwsm-wrapper (lib.getExe pkgs.grimblast)} edit active"
          "SUPER CTRL,  P,      exec, ${uwsm-wrapper (lib.getExe pkgs.grimblast)} edit screen"

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
        ++ (map-workspaces (no: repr: "SUPER, ${no}, workspace, ${repr}"))
        ++ (map-workspaces (no: repr: "SUPER SHIFT, ${no}, hy3:movetoworkspace, ${repr}"));
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
        "move 2426 94, class:^$, title:^Picture in picture$"
        "size 640 360, class:^$, title:^Picture in picture$"
        "keepaspectratio, class:^$, title:^Picture in picture$"
        # Firefox's Picture-in-Picture.
        "float, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
        "pin, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
        "move 2426 94, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
        "size 640 360, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
        "keepaspectratio, class:^(firefox|librewolf)$, title:^Picture-in-Picture$"
      ];
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

    waybar = {
      enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
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
  };

  services.hypridle = {
    enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
    settings = let
      hyprctl = lib.getExe' pkgs.hyprland "hyprctl";
      hyprlock = lib.getExe pkgs.hyprlock;
      loginctl = lib.getExe' pkgs.systemd "loginctl";
      systemctl = lib.getExe' pkgs.systemd "systemctl";

      # Avoid starting multiple hyprlock instances.
      lock = "${lib.getExe' pkgs.procps "pidof"} ${hyprlock} || ${hyprlock}";
    in {
      general = {
        lock_cmd = lock;
        unlock_cmd = "pkill -USR1 ${hyprlock}";

        before_sleep_cmd = "${loginctl} lock-session"; # lock before suspend.
        after_sleep_cmd = "${hyprctl} dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
      };

      listener =
        lib.optionals flags.lockScreen.enable [
          {
            inherit (flags.lockScreen) timeout;
            on-timeout = lock;
          }
        ]
        ++ [
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
