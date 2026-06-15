{ self, inputs, ... }:
{
  flake.homeModules.programs-wayland-hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.nix-config-colorscheme.homeModules.hyprland ];

      options.node.wayland = with lib; {
        hyprland = {
          monitors = mkOption {
            description = ''
              Output configuration.

              # Framework 13" 2.8k
              monitor = "eDP-1, 2880x1920@120.00000, 0x0, 2.00";
              # Alienware Dell AW3225QF 32"
              monitor = "DP-3, 3840x2160@239.991Hz, 0x0, 1.25";
              # Apple Pro Display XDR
              monitor = "DP-3, 6016x3384@60.00Hz, 0x0, 2.00";
            '';
            example = literalExpression ''
              {
                output = "eDP-1";
                mode = "2880x1920@120";
                position = "0x0";
                scale = 2.0;
                transform = 0;
              }
            '';
            default = [ ];
            type = types.listOf (
              types.submodule {
                options = {
                  output = mkOption {
                    type = types.str;
                    example = "eDP-1";
                    description = "The name of the output.";
                  };
                  mode = mkOption {
                    type = types.str;
                    example = "2880x1920@120";
                    description = "The resolution and frame rate of the monitor.";
                  };
                  position = mkOption {
                    type = types.str;
                    default = "0x0";
                    description = "The position of the monitor relative to others.";
                  };
                  scale = mkOption {
                    type = with types; oneOf [float int];
                    default = 1.0;
                    example = 2.0;
                    description = "The scale of the monitor.";
                  };
                  transform = mkOption {
                    type = types.ints.between 0 7;
                    default = 0;
                    description = ''
                      | Transform              | x |
                      + ---------------------- + - +
                      | normal (no transforms) | 0 |
                      | 90 degrees             | 1 |
                      | 180 degrees            | 2 |
                      | 270 degrees            | 3 |
                      | flipped                | 4 |
                      | flipped + 90 degrees   | 5 |
                      | flipped + 180 degrees  | 6 |
                      | flipped + 270 degrees  | 7 |
                    '';
                  };
                };
              }
            );
          };

          touchpad = {
            clickfinger_behavior = mkEnableOption ''
              When enabled, button presses with 1, 2, or 3 fingers will be
              mapped to LMB, RMB, and MMB respectively.

              This disables interpretation of clicks based on location on the
              touchpad.
            '';
          };

          exec-start = mkOption {
            type = types.attrsOf types.package;
            example = literalExpression ''
              {
                "1" = config.programs.chromium.package;
                "3" = config.programs.kitty.package;
              }
            '';
            default = {
              "1" = config.programs.chromium.package;
              "3" = config.user.terminal.default.package;
            };
          };
        };

        hyprlauncher = {
          package = mkPackageOption pkgs "hyprlauncher" {
            extraDescription = ''
              The `hyprlauncher` package to use.
            '';
          };

          desktop_launch_prefix = mkOption {
            type = types.str;
            default = config.node.wayland.uwsm-wrapper.prefix;
            description = ''
              Launch prefix for each desktop app, e.g. `uwsm app -- `.
            '';
            example = literalExpression ''
              uwsm app --
            '';
          };
        };

        idle = {
          screensaver = {
            enable = mkEnableOption "Enable screensaver" // {
              default = config.wayland.windowManager.hyprland.enable;
            };

            timeout = mkOption {
              type = types.int;
              default = 5 * 60; # 5 minutes
              description = ''
                The amount of idle time, in seconds, before enabling the screen saver.
              '';
            };
          };

          screenlock = {
            enable = mkEnableOption "Enable screenlock";

            package = mkPackageOption pkgs "hyprlock" {
              extraDescription = ''
                The screenlock package to use.
              '';
            };

            timeout = mkOption {
              type = types.int;
              default = 10 * 60; # 10 minutes
              description = ''
                The amount of idle time, in seconds, before enabling the lock screen.
              '';
            };

            fingerprint.enable = mkEnableOption "Enable fingerprint unlock";
          };

          suspend = {
            enable = mkEnableOption "Enable suspend" // {
              default = config.wayland.windowManager.hyprland.enable;
            };

            timeout = mkOption {
              type = types.int;
              default = 30 * 60; # 30 minutes
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
              default = 2 * 60 * 60; # 2 hours
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
              default = 30 * 60; # 30 minutes
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

      config =
        let
          cfg = config.node.wayland;
          uwsmGetExe = pkg: lib.getExe pkg |> cfg.uwsm-wrapper.wrapper;
          uwsmGetExe' = pkg: fname: lib.getExe' pkg fname |> cfg.uwsm-wrapper.wrapper;
        in
        {
          wayland.windowManager.hyprland = {
            enable = true;
            configType = "lua";

            # Set the Hyprland and XDPH packages to null to use the ones from the NixOS module
            package = lib.mkDefault null;
            portalPackage = lib.mkDefault null;

            # Managed by UWSM
            systemd.enable = false;

            # Layout plugin
            plugins = with pkgs.hyprlandPlugins; [ hy3 ];

            # Hyprland configuration
            settings.config = {
              ecosystem = {
                no_update_news = true;
                no_donation_nag = true;
              };

              # Properly scale X11 applications (e.g. 1Password) by unscaling XWayland
              xwayland.force_zero_scaling = true;

              # Keyboard input setup
              input = {
                kb_options = "ctrl:nocaps";
                kb_layout = "us";
                kb_variant = "mac";
                repeat_delay = 200;
                repeat_rate = 60;

                touchpad = {
                  inherit (cfg.hyprland.touchpad) clickfinger_behavior;
                  natural_scroll = true;
                  scroll_factor = 0.25;
                };
              };
              general = {
                layout = "hy3"; # Requires the hy3 plugin
                border_size = 1;
                gaps_in = 4;
                gaps_out = 8;
              };
              decoration = {
                rounding = 12;
                blur.enabled = false;
                shadow = {
                  enabled = true;
                  range = 4;
                  render_power = 3;
                };
              };
              misc = {
                disable_hyprland_logo = true;
                force_default_wallpaper = 0;
              };
            };
            extraConfig =
              let
                set-aspect-ratio =
                  with pkgs;
                  writeShellApplication {
                    name = "set-aspect-ratio";
                    runtimeInputs = [
                      bc
                      jq
                    ];
                    text = ''
                      focused_window=$(hyprctl activewindow -j)

                      width=$(echo "$focused_window" | jq -r '.size[0]')
                      height=$(echo "scale=0; ($width * $2 / $1) / 1" | bc -l)

                      hyprctl dispatch resizeactive exact "$width" "$height"
                    '';
                  };
                capture-screenshot =
                  with pkgs;
                  writeShellApplication {
                    name = "screenshot-editor";
                    runtimeInputs = [
                      grimblast
                      wl-clipboard
                      satty
                    ];
                    text = ''
                      grimblast save "$@" - | satty --filename - \
                        --copy-command=wl-copy \
                        --output-filename "${config.xdg.userDirs.download}/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" \
                        --early-exit \
                        --action-on-enter save-to-clipboard \
                        --save-after-copy
                    '';
                  };

                map-workspaces =
                  mapFn:
                  builtins.genList (x: x) 10
                  |> map (x: mapFn (toString x) (if x == 0 then "10" else (toString x)))
                  |> lib.concatStringsSep "\n";
                map-movements =
                  mapFn:
                  lib.attrsets.mapAttrsToList mapFn {
                    "left" = "l";
                    "right" = "r";
                    "up" = "u";
                    "down" = "d";
                  }
                  |> lib.concatStringsSep "\n";
                map-monitors = mapFn: map mapFn cfg.hyprland.monitors |> lib.concatStringsSep "\n";
              in
              ''
                -- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/#xdg-specifications
                hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
                hl.env("XDG_SESSION_TYPE", "wayland")
                hl.env("XDG_SESSION_DESKTOP", "Hyprland")

                -- Keyboard bindings
                hl.bind("SUPER         + Return", hl.dsp.exec_cmd("${uwsmGetExe config.user.terminal.default.package}"))
                hl.bind("SUPER         + Space",  hl.dsp.exec_cmd("${uwsmGetExe config.node.wayland.hyprlauncher.package} --toggle"))
                hl.bind("SUPER + SHIFT + X",      hl.dsp.window.close())
                hl.bind("SUPER + SHIFT + Q",      hl.dsp.exec_cmd("${lib.getExe pkgs.uwsm} stop"))
                hl.bind("SUPER + SHIFT + L",      hl.dsp.exec_cmd("${uwsmGetExe config.node.wayland.idle.screenlock.package}"))
                hl.bind("SUPER         + V",      hl.dsp.window.float({ action = "toggle" }))
                hl.bind("SUPER         + F",      hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
                hl.bind("SUPER + SHIFT + F",      hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
                hl.bind("SUPER + CTRL  + C",      hl.dsp.exec_cmd("${uwsmGetExe pkgs.hyprpicker} -a"))
                hl.bind("SUPER         + P",      hl.dsp.exec_cmd("${uwsmGetExe capture-screenshot} area"))
                hl.bind("SUPER + SHIFT + P",      hl.dsp.exec_cmd("${uwsmGetExe capture-screenshot} active"))
                hl.bind("SUPER + CTRL  + P",      hl.dsp.exec_cmd("${uwsmGetExe capture-screenshot} screen"))

                hl.bind("SUPER + ALT   + R",      hl.dsp.exec_cmd("${uwsmGetExe set-aspect-ratio} 16 9"))

                local hy3 = hl.plugin.hy3

                hl.bind("SUPER         + D",      hy3.make_group("h"))
                hl.bind("SUPER         + S",      hy3.make_group("v"))
                hl.bind("SUPER         + Z",      hy3.make_group("tab"))
                hl.bind("SUPER         + A",      hy3.change_focus("raise"))
                hl.bind("SUPER + SHIFT + A",      hy3.change_focus("lower"))
                hl.bind("SUPER         + E",      hy3.expand("expand"))
                hl.bind("SUPER + SHIFT + E",      hy3.expand("base"))
                hl.bind("SUPER         + R",      hy3.change_group("opposite"))

                hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("${uwsmGetExe' pkgs.swayosd "swayosd-client"} --output-volume lower"))
                hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("${uwsmGetExe' pkgs.swayosd "swayosd-client"} --output-volume mute-toggle"))
                hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("${uwsmGetExe' pkgs.swayosd "swayosd-client"} --output-volume raise"))
                hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("${uwsmGetExe pkgs.brightnessctl} set 10%-"))
                hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("${uwsmGetExe pkgs.brightnessctl} set +10%"))

                -- Media key
                hl.bind("XF86AudioMedia", hl.dsp.exec_cmd("${uwsmGetExe pkgs.playerctl} play-pause"))
                hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("${uwsmGetExe pkgs.playerctl} next"))
                hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("${uwsmGetExe pkgs.playerctl} play-pause"))
                hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("${uwsmGetExe pkgs.playerctl} previous"))
                hl.bind("XF86AudioStop",  hl.dsp.exec_cmd("${uwsmGetExe pkgs.playerctl} stop"))

                -- Mouse
                hl.bind("SUPER + mouse:272", hl.dsp.window.drag())   -- Left mouse button
                hl.bind("SUPER + mouse:273", hl.dsp.window.resize()) -- Right mouse button
              ''
              + (map-movements (
                dir: key: ''hl.bind("SUPER         + ${dir}", hy3.move_focus("${key}", { wrap = true }))''
              ))
              + ""
              + (map-movements (
                dir: key: ''hl.bind("SUPER + SHIFT + ${dir}", hy3.move_window("${key}", { once = true }))''
              ))
              + ""
              + (map-workspaces (
                no: repr: ''hl.bind("SUPER         + ${no}", hl.dsp.focus({ workspace = ${repr} }))''
              ))
              + ""
              + (map-workspaces (
                no: repr: ''hl.bind("SUPER + SHIFT + ${no}", hy3.move_to_workspace("${repr}"))''
              ))
              + (map-monitors (monitor: ''

                -- Keep the blank line above
                hl.monitor({
                  output = "${monitor.output}",
                  mode = "${monitor.mode}",
                  position = "${monitor.position}",
                  scale = ${toString monitor.scale},
                  transform = ${toString monitor.transform},
                })
              ''))
              + ''
                hl.curve("expressiveFastSpatial",    { type = "bezier", points = { { 0.42, 1.67 }, { 0.21, 0.90 } } })
                hl.curve("expressiveSlowSpatial",    { type = "bezier", points = { { 0.39, 1.29 }, { 0.35, 0.98 } } })
                hl.curve("expressiveDefaultSpatial", { type = "bezier", points = { { 0.38, 1.21 }, { 0.22, 1.00 } } })
                hl.curve("emphasizedDecel",          { type = "bezier", points = { { 0.05, 0.70 }, {  0.1, 1.00 } } })
                hl.curve("emphasizedAccel",          { type = "bezier", points = { { 0.30, 0.00 }, {  0.8, 0.15 } } })

                -- https://wiki.hyprland.org/Configuring/Animations/#animation-tree
                -- name, on/off, speed (100ms increments), curve, style
                hl.animation({ leaf = "global",      enabled = true,  speed = 1.2, bezier = "emphasizedDecel" })
                hl.animation({ leaf = "fade",        enabled = true,  speed = 1.2, bezier = "emphasizedDecel" })
                hl.animation({ leaf = "layers",      enabled = true,  speed = 1.2, bezier = "emphasizedDecel", style = "popin 93%" })
                hl.animation({ leaf = "windowsIn",   enabled = true,  speed = 1.2, bezier = "emphasizedDecel", style = "slidefade 90%" })
                hl.animation({ leaf = "windowsMove", enabled = true,  speed = 1.2, bezier = "emphasizedDecel", style = "slide" })
                hl.animation({ leaf = "windowsOut",  enabled = true,  speed = 1.2, bezier = "emphasizedAccel", style = "slidefade 90%" })
                hl.animation({ leaf = "workspaces",  enabled = false, speed = 2,   bezier = "emphasizedDecel", style = "slide" })

                -- Open apps and start daemons on startup
                hl.on("hyprland.start", function()
                  ${
                    let
                      execCmd = workspace: pkg: ''
                        hl.exec_cmd("${uwsmGetExe pkg}", { workspace = "${workspace}" })
                      '';
                    in
                    with lib;
                    mapAttrsToList execCmd cfg.hyprland.exec-start |> concatStringsSep "\n"
                  }
                  hl.exec_cmd("${uwsmGetExe config.node.wayland.hyprlauncher.package} --daemon")
                end)

                hl.window_rule({
                  name = "Thunar operation in progress dialog",
                  match = { class = "^thunar$", title = "^File Operation Progress$" },
                  float = true,
                })
                hl.window_rule({
                  name = "Bitwarden Chrome extension",
                  match = { class = "^chrome-nngceckbapebfimnlniiiahkandclblb-Default$", title = "^_crx_nngceckbapebfimnlniiiahkandclblb$" },
                  float = true,
                })
                hl.window_rule({
                  name = "Chrome's Picture-in-Picture",
                  match = { class = "^$", title = "^Picture in picture$" },
                  float = true,
                  pin = true,
                  keep_aspect_ratio = true,
                  move = { "monitor_w - ${
                    toString (cfg.pip.width + cfg.pip.margin.x)
                  }", ${toString cfg.pip.margin.y} },
                  size = { ${toString cfg.pip.width}, ${toString cfg.pip.height} },
                })
              '';
          };

          programs.hyprlock =
            let
              cfg = config.node.wayland.idle.screenlock;
            in
            {
              enable = lib.mkDefault cfg.enable;
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
              settings =
                let
                  cfg = config.node.wayland.idle;

                  hyprctl = uwsmGetExe' pkgs.hyprland "hyprctl";
                  screenlock = uwsmGetExe config.node.wayland.idle.screenlock.package;
                  loginctl = uwsmGetExe' pkgs.systemd "loginctl";
                  systemctl = uwsmGetExe' pkgs.systemd "systemctl";

                  # Avoid starting multiple screenlock instances
                  lock = "${uwsmGetExe' pkgs.procps "pidof"} ${screenlock} || ${screenlock}";
                in
                {
                  general = {
                    after_sleep_cmd = "${hyprctl} dispatch dpms on"; # To avoid having to press a key twice to turn on the display
                  }
                  // lib.optionalAttrs cfg.screenlock.enable {
                    lock_cmd = lock;
                    unlock_cmd = "pkill -USR1 ${screenlock}";

                    before_sleep_cmd = "${loginctl} lock-session"; # Lock before suspend
                  };

                  listener =
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

          xdg.configFile."hypr/hyprlauncher.conf".text =
            let
              cfg = config.node.wayland.hyprlauncher;
            in
            ''
              finders {
                  desktop_icons = false
                  desktop_launch_prefix = ${cfg.desktop_launch_prefix}
              }

              ui {
                  window_size = 640 360
              }
            '';

          assertions =
            let
              cfg = config.node.wayland.idle;
            in
            [
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
    };
}
