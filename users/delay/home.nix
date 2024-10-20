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
  inherit (config.modules.usrenv) isHeadless switcherApp;
  inherit (pkgs.stdenv) isDarwin isLinux;

  # Unstable package repository.
  upkgs = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
  };

  hasWindowManager = !isHeadless;
in rec {
  imports = [
    inputs.catppuccin.homeManagerModules.catppuccin

    ./fonts.nix
    ./scripts.nix
    ./shells.nix
    ./ssh.nix
    ./terminals.nix
    ./wayland.nix
    ./x11.nix
  ];

  # Packages I always want installed. Most packages I install using per-project
  # flakes sourced with direnv and nix-shell, so this is not a huge list.
  home.packages =
    [
      pkgs.coreutils # For consistency across platforms (i.e. GNU utils on macOS).
      pkgs.duf # Modern `df` alternative.
      pkgs.git-get # Used along with fzf and terminal multiplexers for repository management.
      pkgs.libqalculate # Multi-purpose calculator on the command line.
      pkgs.tree # List the content of directories in a tree-like format.
      pkgs.yazi # File explorer that supports Kitty image protocol.

      # Our own package installed by overlay.
      # It's important to keep shadowing the original `pkgs.nvim` package
      # instead of referring to our custom config via another name to maintain
      # all related integrations (e.g. MANPAGER) while being able to override it
      # at anytime (e.g. in the corp-specific flavor).
      pkgs.nvim
    ]
    ++ lib.optionals (switcherApp == "zellij") [
      # TODO: remove once injected properly.
      pkgs.zellij-select-repository
    ]
    ++ lib.optionals hasWindowManager [pkgs.ghostty]
    ++ lib.optionals isLinux [pkgs.valgrind]
    ++ lib.optionals (isLinux && hasWindowManager) [
      pkgs.chromium
      pkgs.firefox-devedition
      pkgs.rofi
    ];

  home.sessionVariables = rec {
    LANG = "en_US.UTF-8";
    LC_CTYPE = LANG;
    LC_ALL = LANG;
    EDITOR = lib.getExe pkgs.nvim;
    MANPAGER = "${EDITOR} +Man!";
    PAGER = "less -FirSwX";
  };

  # Configure catppuccin theme applied throughout the configuration.
  catppuccin.flavor = "mocha";

  programs.jujutsu = {
    enable = true;
    # Install jujutsu from `nixpkgs-unstable`.
    package = upkgs.jujutsu;
    settings =
      lib.recursiveUpdate {
        user = {
          email = "0@0xcharly.com";
          name = "Charly Delay";
        };
        template-aliases."format_timestamp(timestamp)" = "timestamp.ago()";
        ui."default-command" = "status";
        ui.pager = lib.getExe pkgs.delta;
        ui.diff.format = "git";
        signing = {
          sign-all = true;
          backend = "ssh";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPf5EWFb/MW+1ZdQxDLZJWPrgrtibMcCmmKeCp+QMWBl";
        };
      }
      (lib.optionalAttrs isDarwin {signing.backends.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";});
  };

  # Jujutsu config path is wrong on macOS.
  # Fixed in 24.11 (https://github.com/nix-community/home-manager/pull/5416).
  # TODO: delete this once 24.11 lands.
  home.file = lib.optionalAttrs isDarwin {
    "Library/Application Support/jj/config.toml".source = let
      tomlFormat = pkgs.formats.toml {};
    in
      tomlFormat.generate "jujutsu-config" programs.jujutsu.settings;
  };

  programs.git = {
    enable = true;
    userName = "Charly Delay";
    userEmail = "0@0xcharly.com";
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPf5EWFb/MW+1ZdQxDLZJWPrgrtibMcCmmKeCp+QMWBl";
      signByDefault = true;
    };
    ignores = [
      "/.direnv/"
    ];
    delta = {
      enable = true;
      catppuccin.enable = true;
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      github.user = "0xcharly";
      push.default = "tracking";
      init.defaultBranch = "main";
      branch.sort = "-committerdate";
      gpg = {
        format = "ssh";
        ssh.program = lib.mkIf isDarwin "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
      commit.gpgsign = true;
      gitget = {
        root = "~/code";
        host = "github.com";
      };
    };
  };

  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    secureSocket = true;
    sensibleOnTop = false;
    # Do not force catppuccin theme here since it sets the "default" value to a
    # solid color, which doesn't play well with translucent terminal background.
    catppuccin.enable = false;

    extraConfig = builtins.readFile ./tmux.conf;
  };

  programs.zellij = {
    enable = true;
    catppuccin.enable = true;
    settings = {
      scrollback_editor = lib.getExe pkgs.nvim;
      keybinds.normal.bind = lib.mkIf (switcherApp == "zellij") {
        _args = ["Ctrl f"];
        Run = "zellij-select-repository";
      };
      ui.pane_frames.rounded_corners = true;
      plugins.sessionizer._props = {location = "file:${lib.getExe pkgs.zellij-switch-repository}";};
    };
  };
}
