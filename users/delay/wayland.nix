{
  inputs,
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (pkgs.stdenv) isLinux;
  inherit (config.modules.usrenv) compositor;

  enable = isLinux && compositor == "wayland";
in rec {
  imports = [inputs.hyprland.homeManagerModules.default];

  programs = lib.mkIf enable {
    chromium.commandLineArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform-hint=auto"
      "--ozone-platform=wayland"
    ];
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      catppuccin.enable = true;
    };
    swaylock = {
      enable = true;
      catppuccin.enable = true;
    };
  };

  home.packages = lib.optionals enable (with pkgs; [
    grim # Screenshot functionality
    slurp # Screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    wlr-randr # Utility to manage outputs of a Wayland compositor
  ]);

  home.sessionVariables = lib.mkIf enable {
    NIXOS_OZONE_WL = 1;

    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    XDG_SESSION_TYPE = "wayland";

    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_AUTO_SCREEN_SCALE_FACTOR = 0;
    QT_SCALE_FACTOR = 1;
    GDK_SCALE = 1;
    GDK_DPI_SCALE = 1;
    MOZ_ENABLE_WAYLAND = 1;
    _JAVA_AWT_WM_NONREPARENTING = 1;
    XCURSOR = "Catppuccin-Mocha-Dark-Cursors";
    XCURSOR_SIZE = 24;
  };

  xdg.configFile = lib.mkIf enable {
    "electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform --ozone-platform-hint=auto --ozone-platform=wayland
    '';
  };

  wayland.windowManager.hyprland = {
    inherit enable;
    catppuccin.enable = true;
    systemd.variables = ["--all"];
    plugins = [inputs.hy3.packages."${pkgs.system}".hy3];
    settings = {
      # Open apps on startup.
      exec-once = [
        "systemctl --user enable --now hyprpaper.service"
        "[workspace 1] ${lib.getExe args.config.programs.firefox.finalPackage}"
        "[workspace 2] ${lib.getExe args.config.programs.chromium.package}"
        "[workspace 3] ${lib.getExe pkgs.ghostty}"
      ];

      # Monitor scaling.
      monitor = "DP-3, 3840x2160@239.991Hz, 0x0, 1.25";
      # Properly scale X11 applications (e.g. 1Password).
      # Unscale XWayland
      xwayland.force_zero_scaling = true;
      # Toolkit-specific scale
      env = [
        "GDK_SCALE,1.25"
        "GDK_DPI_SCALE,1.25"
        "XCURSOR_SIZE,32"
      ];

      # Keyboard input setup.
      input = {
        kb_options = "ctrl:nocaps";
        kb_layout = "us";
        # kb_variant = "intl";
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
        "SUPER,       Return, exec, ${lib.getExe pkgs.ghostty}"
        "SUPER,       Space,  exec, ${lib.getExe args.config.programs.rofi.package} -show drun"
        "SUPER SHIFT, X,      killactive, "
        "SUPER SHIFT, Q,      exit, "
        "SUPER,       V,      togglefloating, "
        "SUPER CTRL,  L,      exec, ${lib.getExe args.config.programs.swaylock.package}"

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
        "ALT SHIFT,   1,      hy3:movetoworkspace, 1"
        "ALT SHIFT,   2,      hy3:movetoworkspace, 2"
        "ALT SHIFT,   3,      hy3:movetoworkspace, 3"
        "ALT SHIFT,   4,      hy3:movetoworkspace, 4"
        "ALT SHIFT,   5,      hy3:movetoworkspace, 5"

        "SUPER CTRL,  1,      hy3:focustab, 1"
        "SUPER CTRL,  2,      hy3:focustab, 2"
        "SUPER CTRL,  3,      hy3:focustab, 3"
        "SUPER CTRL,  4,      hy3:focustab, 4"
        "SUPER CTRL,  5,      hy3:focustab, 5"
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
        "float, class:^firefox$, title: ^Picture-in-Picture$"
        "pin, class:^firefox$, title: ^Picture-in-Picture$"
        "move 2550 10, class:^firefox$, title: ^Picture-in-Picture$"
        "size 512 288, class:^firefox$, title: ^Picture-in-Picture$"
      ];
    };
  };

  # Notifications.
  services.mako = lib.mkIf enable {
    enable = true;
    catppuccin.enable = true;
    # Sets the border radius to -1 that of the hyprland windows since it's
    # offset by -1-1 pixels. This results in "parallel" rounding.
    borderRadius = wayland.windowManager.hyprland.settings.decoration.rounding - 1;
    borderSize = 2;
    font = "Comic Code 12";
    maxIconSize = 32;
    padding = "8";
    width = 512;
  };

  # Wallpaper.
  services.hyprpaper = lib.mkIf enable {
    enable = true;
    settings = let
      wallpaper = ./wallpapers/anime-room.png;
      wallpaper_path = toString wallpaper;
    in {
      ipc = true;
      splash = false;
      preload = [wallpaper_path];
      wallpaper = [", ${wallpaper_path}"];
    };
  };

  # Make cursor not tiny on HiDPI screens.
  home.pointerCursor = lib.mkIf enable {
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 256;
    gtk.enable = true;
    x11.enable = true;
  };
}
