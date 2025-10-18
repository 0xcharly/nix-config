{flake, ...}: {
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [flake.modules.home.wayland-uwsm];

  options.node.wayland = with lib; {
    hyprland = {
      monitor = mkOption {
        type = types.str;
        example = "DP-3, 6016x3384@60.00Hz, 0x0, 2.00";
        description = ''
          # Apple Pro Display XDR.
          monitor = "DP-3, 6016x3384@60.00Hz, 0x0, 2.00";
          # Alienware Dell AW3225QF 32".
          monitor = "DP-3, 3840x2160@239.991Hz, 0x0, 1.25";
          # Framework 13" 2.8k.
          monitor = "eDP-1, 2880x1920@120.00000, 0x0, 2.00";
        '';
      };
    };

    idle = {
      screensaver = {
        enable = mkOption {
          type = types.bool;
          default = config.wayland.windowManager.hyprland.enable;
          description = ''
            Enable screen saver.
          '';
        };

        timeout = mkOption {
          type = types.int;
          default = 5 * 60; # 5 minutes.
          description = ''
            The amount of idle time, in seconds, before enabling the screen saver.
          '';
        };
      };

      screenlock = {
        enable = mkOption {
          type = types.bool;
          default = config.wayland.windowManager.hyprland.enable;
          description = ''
            Enable screenlock.
          '';
        };

        timeout = mkOption {
          type = types.int;
          default = 10 * 60; # 10 minutes.
          description = ''
            The amount of idle time, in seconds, before enabling the lock screen.
          '';
        };

        fingerprint.enable = mkEnableOption "Enable fingerprint unlock";
      };

      suspend = {
        enable = mkOption {
          type = types.bool;
          default = config.wayland.windowManager.hyprland.enable;
          description = ''
            Enable suspend.
          '';
        };

        timeout = mkOption {
          type = types.int;
          default = 30 * 60; # 30 minutes.
          description = ''
            The amount of idle time, in seconds, before suspending.

            # Suspend (a.k.a. Suspend-to-RAM, Sleep)

            - What happens:
              - The system state (running programs, open files, etc.) stays in
                RAM.
              - Most hardware powers down, except RAM, which is kept powered at
                a very low level to preserve its contents.
              - CPU, GPU, disks, and peripherals are powered off or put in
                low-power states.
            - Power usage: Very low, but not zero — the machine must keep
              feeding power to RAM.
            - Resume speed: Very fast (a few seconds).
            - Downside: If the machine loses power (battery dies, unplugged
              desktop, etc.), the RAM contents are lost and the session is gone.
          '';
        };
      };

      hibernate = {
        enable = mkEnableOption "Enable hibernate";

        timeout = mkOption {
          type = types.int;
          default = 2 * 60 * 60; # 2 hours.
          description = ''
            The amount of idle time, in seconds, before hibernating.

            # Hibernate (a.k.a. Suspend-to-Disk)

            - What happens:
              - The system state (contents of RAM) is written to swap space (or
                a swap file) on disk.
              - The machine then fully powers down — no electricity required.
              - Power usage: Zero while off.
            - Resume speed: Slower than suspend (needs to reload RAM image from
              disk).
            - Upside: Safe against power loss — your session is preserved even
              if the battery dies.
            - Downside: Requires enough swap space to store all RAM contents.
              Resume can take longer.
          '';
        };
      };

      hybrid-sleep = {
        enable = mkEnableOption "Enable hybrid-sleep";

        timeout = mkOption {
          type = types.int;
          default = 30 * 60; # 30 minutes.
          description = ''
            The amount of idle time, in seconds, before triggering hybrid-sleep.

            # Hybrid suspend

            - RAM state is written to disk (like hibernate), then the system
              suspends (like suspend).
            - If power remains, wake is fast (like suspend).
            - If power is lost, state is restored from disk (like hibernate).
          '';
        };
      };
    };
  };

  config = {
    wayland.windowManager.hyprland = let
      cfg = config.node.wayland;
      uwsmGetExe = pkg: cfg.uwsm-wrapper.wrapper (lib.getExe pkg);
      uwsmGetExe' = pkg: fname: cfg.uwsm-wrapper.wrapper (lib.getExe' pkg fname);
    in {
      enable = true;

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
          "[workspace 1] ${uwsmGetExe config.programs.zen-browser.package}"
          "[workspace 3] ${uwsmGetExe config.programs.ghostty.package}"
        ];

        # Monitor config.
        inherit (cfg.hyprland) monitor;

        # Properly scale X11 applications (e.g. 1Password) by unscaling XWayland.
        xwayland.force_zero_scaling = true;

        # Keyboard input setup.
        input = {
          kb_options = "ctrl:nocaps";
          kb_layout = "us";
          kb_variant = "mac";
          repeat_delay = 200;
          repeat_rate = 60;

          touchpad.natural_scroll = true;
        };
        general = {
          layout = "hy3"; # Requires the hy3 plugin.
          border_size = 2;
          gaps_in = 2;
          gaps_out = 4;
          "col.active_border" = "rgb(9fcdfe)";
          "col.inactive_border" = "rgb(1d2938)";
        };
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
        bind = let
          screenshot-editor = pkgs.writeShellApplication {
            name = "screenshot-editor";
            runtimeInputs = with pkgs; [wl-clipboard satty];
            text = ''
              satty --filename - \
                --copy-command=wl-copy \
                --output-filename "${config.xdg.userDirs.download}/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" \
                --early-exit \
                --action-on-enter save-to-clipboard \
                --save-after-copy
            '';
          };

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
        in
          [
            "SUPER,       Return, exec, ${uwsmGetExe config.programs.ghostty.package}"
            "SUPER,       Space,  exec, ${uwsmGetExe config.programs.walker.package}"
            "SUPER SHIFT, X,      killactive, "
            "SUPER SHIFT, Q,      exec, ${uwsmGetExe' pkgs.systemd "loginctl"} terminate-session \"$XDG_SESSION_ID\""
            "SUPER SHIFT, L,      exec, ${uwsmGetExe config.programs.hyprlock.package}"
            "SUPER,       V,      togglefloating, "
            "SUPER,       F,      fullscreen, "
            "SUPER CTRL,  C,      exec, ${uwsmGetExe pkgs.hyprpicker} -a"
            "SUPER,       P,      exec, ${uwsmGetExe pkgs.hyprshot} -m region --raw | ${uwsmGetExe screenshot-editor}"
            "SUPER SHIFT, P,      exec, ${uwsmGetExe pkgs.hyprshot} -m window --raw | ${uwsmGetExe screenshot-editor}"
            "SUPER CTRL,  P,      exec, ${uwsmGetExe pkgs.hyprshot} -m output --raw | ${uwsmGetExe screenshot-editor}"

            "SUPER ALT,   F,      exec, ${uwsmGetExe config.programs.firefox.finalPackage}"
            "SUPER ALT,   G,      exec, ${uwsmGetExe config.programs.chromium.package}"
            "SUPER ALT,   Z,      exec, ${uwsmGetExe config.programs.zen-browser.package}"
            "SUPER ALT,   S,      exec, ${uwsmGetExe pkgs.bitwarden}"

            "SUPER,       D,      hy3:makegroup,   h"
            "SUPER,       S,      hy3:makegroup,   v"
            "SUPER,       Z,      hy3:makegroup,   tab"
            "SUPER,       A,      hy3:changefocus, raise"
            "SUPER SHIFT, A,      hy3:changefocus, lower"
            "SUPER,       E,      hy3:expand,      expand"
            "SUPER SHIFT, E,      hy3:expand,      base"
            "SUPER,       R,      hy3:changegroup, opposite"
          ]
          ++ [
            ", XF86AudioLowerVolume,  exec, ${uwsmGetExe' pkgs.swayosd "swayosd-client"} --output-volume lower"
            ", XF86AudioMute,         exec, ${uwsmGetExe' pkgs.swayosd "swayosd-client"} --output-volume mute-toggle"
            ", XF86AudioRaiseVolume,  exec, ${uwsmGetExe' pkgs.swayosd "swayosd-client"} --output-volume raise"
            ", XF86MonBrightnessDown, exec, ${uwsmGetExe' pkgs.swayosd "swayosd-client"} --brightness lower"
            ", XF86MonBrightnessUp,   exec, ${uwsmGetExe' pkgs.swayosd "swayosd-client"} --brightness raise"

            ", XF86AudioMedia, exec, ${uwsmGetExe pkgs.playerctl} play-pause"
            ", XF86AudioNext,  exec, ${uwsmGetExe pkgs.playerctl} next"
            ", XF86AudioPlay,  exec, ${uwsmGetExe pkgs.playerctl} play-pause"
            ", XF86AudioPrev,  exec, ${uwsmGetExe pkgs.playerctl} previous"
            ", XF86AudioStop,  exec, ${uwsmGetExe pkgs.playerctl} stop"
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
        windowrulev2 = let
          # Position the PiP window in the top right corner.
          pipPosX = toString (cfg.display.logicalResolution.width - cfg.pip.width - cfg.pip.margin.x);
          pipPosY = toString (cfg.pip.margin.y);
        in [
          # Thunar operation in progress dialog.
          "float, class:^thunar$, title:^File Operation Progress$"
          # Volume control.
          "float, class:^org.pulseaudio.pavucontrol$, title:^Volume Control$"
          # Bitwarden extension.
          "float, class:^(firefox|zen-beta)$, title:^(Extension: \(Bitwarden Password Manager\))(.*)$"
          # Chrome's Picture-in-Picture.
          "float, class:^$, title:^Picture in picture$"
          "pin, class:^$, title:^Picture in picture$"
          "move ${pipPosX} ${pipPosY}, class:^$, title:^Picture in picture$"
          "size ${toString cfg.pip.width} ${toString cfg.pip.height}, class:^$, title:^Picture in picture$"
          "keepaspectratio, class:^$, title:^Picture in picture$"
          # Firefox's Picture-in-Picture.
          "float, class:^(firefox|zen-beta)$, title:^Picture-in-Picture$"
          "pin, class:^(firefox|zen-beta)$, title:^Picture-in-Picture$"
          "move ${pipPosX} ${pipPosY}, class:^(firefox|zen-beta)$, title:^Picture-in-Picture$"
          "size ${toString cfg.pip.width} ${toString cfg.pip.height}, class:^(firefox|zen-beta)$, title:^Picture-in-Picture$"
          "keepaspectratio, class:^(firefox|zen-beta)$, title:^Picture-in-Picture$"
        ];
      };
    };

    programs.hyprlock = let
      cfg = config.node.wayland.idle.screenlock;
    in {
      enable = cfg.enable;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 0;
          hide_cursor = true;
          no_fade_in = false;
        };

        auth."fingerprint:enabled" = cfg.fingerprint.enable;

        background = [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            size = "720, 96";
            position = "0, 0";
            dots_center = true;
            dots_size = 0.2;
            dots_spacing = 0.4;
            fade_on_empty = false;
            font_color = "rgba(225, 232, 244, 1)";
            inner_color = "rgba(29, 37, 48, 1)";
            outer_color = "rgba(29, 41, 56, 1)";
            check_color = "rgba(137, 180, 250, 1)";
            fail_color = "rgba(254, 154, 164, 1)";
            outline_thickness = 2;
            placeholder_text = "<i><span foreground=\"##bac2deff\">×͜×</span></i>";
            shadow_passes = 0;
          }
        ];
      };
    };

    services = {
      hypridle = {
        enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
        settings = let
          hyprctl = lib.getExe' pkgs.hyprland "hyprctl";
          hyprlock = lib.getExe config.programs.hyprlock.package;
          loginctl = lib.getExe' pkgs.systemd "loginctl";
          systemctl = lib.getExe' pkgs.systemd "systemctl";

          # Avoid starting multiple hyprlock instances.
          lock = "${lib.getExe' pkgs.procps "pidof"} ${hyprlock} || ${hyprlock}";
        in {
          general = {
            lock_cmd = lock;
            unlock_cmd = "pkill -USR1 ${hyprlock}";

            before_sleep_cmd = "${loginctl} lock-session"; # Lock before suspend.
            after_sleep_cmd = "${hyprctl} dispatch dpms on"; # To avoid having to press a key twice to turn on the display.
          };

          listener = let
            cfg = config.node.wayland.idle;
          in
            lib.optionals cfg.screenlock.enable [
              {
                inherit (cfg.screenlock) timeout;
                on-timeout = lock;
              }
            ]
            ++ lib.optionals cfg.screensaver.enable [
              {
                inherit (cfg.screensaver) timeout;
                on-timeout = "${hyprctl} dispatch dpms off";
                on-resume = "${hyprctl} dispatch dpms on";
              }
            ]
            ++ lib.optionals cfg.suspend.enable [
              {
                inherit (cfg.suspend) timeout;
                on-timeout = "${systemctl} suspend";
              }
            ]
            ++ lib.optionals cfg.hibernate.enable [
              {
                inherit (cfg.hibernate) timeout;
                on-timeout = "${systemctl} hibernate";
              }
            ]
            ++ lib.optionals cfg.hybrid-sleep.enable [
              {
                inherit (cfg.hybrid-sleep) timeout;
                on-timeout = "${systemctl} hybrid-sleep";
              }
            ];
        };
      };

      swayosd.enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
    };

    assertions = let
      cfg = config.node.wayland.idle;
    in [
      {
        assertion = cfg.suspend.enable -> !cfg.hybrid-sleep.enable;
        message = "suspend and hybrid-sleep are mutually exclusive";
      }
      {
        assertion = cfg.hybrid-sleep.enable -> !cfg.suspend.enable;
        message = "suspend and hybrid-sleep are mutually exclusive";
      }
    ];
  };
}
