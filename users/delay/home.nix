{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (config.modules.usrenv) isHeadless;

  hasWindowManager = !isHeadless;
in rec {
  imports = [
    ./scripts.nix
    ./shells.nix
    ./ssh.nix
    ./wayland.nix
    ./x11.nix
  ];

  # Packages I always want installed. Most packages I install using per-project
  # flakes sourced with direnv and nix-shell, so this is not a huge list.
  home.packages =
    [
      pkgs.coreutils # For consistency across platforms (i.e. GNU utils on macOS).
      pkgs.git-get # Used along with open-local-repository for checkouts management.
      pkgs.tree

      # Our own package installed by overlay.
      # It's important to keep shadowing the original `pkgs.nvim` package
      # instead of referring to our custom config via another name to maintain
      # all related integrations (e.g. MANPAGER) while being able to override it
      # at anytime (e.g. in the corp-specific flavor).
      pkgs.nvim
    ]
    ++ lib.optionals hasWindowManager [pkgs.ghostty]
    ++ lib.optionals isLinux [pkgs.valgrind]
    ++ lib.optionals (isLinux && hasWindowManager) [
      pkgs.firefox-devedition
      pkgs.rofi
    ];

  home.sessionVariables =
    {
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      EDITOR = lib.getExe pkgs.nvim;
      MANPAGER = "${lib.getExe pkgs.nvim} +Man!";
      PAGER = "less -FirSwX";
      SHELL = lib.getExe pkgs.fish;
    }
    // lib.optionalAttrs hasWindowManager {
      TERMINAL = lib.getExe pkgs.ghostty;
    };

  xdg = {
    enable = true;
    configFile = {
      "ghostty/config".source = ./ghostty;
    };
  };

  programs.jujutsu = {
    enable = true;
    settings =
      lib.recursiveUpdate {
        user = {
          email = "0x0@0xcharly.com";
          name = "Charly Delay";
        };
        template-aliases."format_timestamp(timestamp)" = "timestamp.ago()";
        ui."default-command" = "status";
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
  home.file."Library/Application Support/jj/config.toml".source = let
    tomlFormat = pkgs.formats.toml {};
  in
    lib.mkIf isDarwin (tomlFormat.generate "jujutsu-config" programs.jujutsu.settings);

  programs.git = {
    enable = true;
    userName = "Charly Delay";
    userEmail = "0x0@0xcharly.com";
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPf5EWFb/MW+1ZdQxDLZJWPrgrtibMcCmmKeCp+QMWBl";
      signByDefault = true;
    };
    ignores = [
      "/.direnv/"
    ];
    delta.enable = true;
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
    terminal = "tmux";
    aggressiveResize = true;
    secureSocket = true;

    clock24 = true;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    sensibleOnTop = false;

    extraConfig = builtins.readFile ./tmux.conf;
  };
}
