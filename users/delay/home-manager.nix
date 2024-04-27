{ inputs, ... }:

{ config, lib, pkgs, ... }:

let
  sources = import ../../nix/sources.nix;

  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isDarwin isLinux;

  isCorpManaged = lib.filesystem.pathIsDirectory "/google/src/cloud/delay/";

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = (pkgs.writeShellScriptBin "manpager" (if isDarwin then ''
    sh -c 'col -bx | bat -l man -p'
    '' else ''
    cat "$1" | col -bx | bat --language man --style plain
  ''));

  _1passwordAgentPath = (if isDarwin then
      "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "~/.1password/agent.sock"
    );
  _1passwordSshSignPath = (if isDarwin then
      "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else
      "${pkgs._1password-gui}/bin/op-ssh-sign"
    );
in {
  imports = [ (import ./nvim { inputs = inputs; }) ];

  home.stateVersion = "23.11";

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = with pkgs; [
    asciinema
    bat
    fd
    fzf
    gh
    htop
    jq
    ripgrep
    tree
    watch
  ] ++ (lib.optionals isDarwin [
    cachix # This is automatically setup on Linux
    scrcpy
    # tailscale  # TODO: try this out.

  ]) ++ (lib.optionals (isLinux) [
    chromium
    firefox
    rofi
    valgrind
    zathura  # A PDF Viewer.
  ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    PAGER = "less -FirSwX";
    MANPAGER = "${manpager}/bin/manpager";
  };

  xdg.enable = true;
  xdg.configFile = {
  #   "wezterm/wezterm.lua".text = builtins.readFile ./wezterm.lua;
  #   "rofi/config.rasi".text = builtins.readFile ./rofi;
  #  };
  #   # tree-sitter parsers
  #   "nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
  #   "nvim/queries/proto/folds.scm".source =
  #     "${sources.tree-sitter-proto}/queries/folds.scm";
  #   "nvim/queries/proto/highlights.scm".source =
  #     "${sources.tree-sitter-proto}/queries/highlights.scm";
  #   "nvim/queries/proto/textobjects.scm".source =
  #     ./textobjects.scm;
  } // (if isDarwin then {
  #   # Rectangle.app. This has to be imported manually using the app.
  #   "rectangle/RectangleConfig.json".text = builtins.readFile ./RectangleConfig.json;
  } else {}) // (if isLinux then {
  #   "ghostty/config".text = builtins.readFile ./ghostty.linux;
  #   "i3/config".text = builtins.readFile ./i3;
  } else {});

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  xsession = mkIf isLinux {
    enable = true;
    windowManager.i3 = rec {
      enable = true;
      config = {
        modifier = "Mod4";
        startup = [
          { command = "xrandr-auto"; notification = false; }
        ];
        keybindings = import ./i3-keybindings.nix config.modifier;
      };
      #extraConfig = builtins.readFile ./i3;
    };
  };

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStrings (lib.strings.intersperse "\n" ([
      (builtins.readFile ./config.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
    ]));

    shellAliases = if isLinux then {
      pbcopy = "xclip";
      pbpaste = "xclip -o";
    } else {};

    plugins = map (n: {
      name = n;
      src  = sources.${n};
    }) [
      "fish-fzf"
      "fish-foreign-env"
    ];
  };

  programs.wezterm = {
    enable = true;
    package = inputs.wezterm.packages.${pkgs.system}.default;
    extraConfig = builtins.readFile ./wezterm.lua;
  };
  home.sessionVariables.TERMINAL = "wezterm";

  programs.i3status = {
    enable = isLinux;

    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };

    modules = {
      ipv6.enable = false;
      "wireless _first_".enable = false;
      "battery all".enable = false;
    };
  };

  programs.git = {
    enable = true;
    userName = "Charly Delay";
    userEmail = "charly@delay.gg";
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPf5EWFb/MW+1ZdQxDLZJWPrgrtibMcCmmKeCp+QMWBl";
      signByDefault = true;
    };
    aliases = {
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      github.user = "0xcharly";
      push.default = "tracking";
      init.defaultBranch = "main";
      branch.sort = "-committerdate";
      credential."https://github.com".helper = "!gh auth git-credential";
      credential."https://gist.github.com".helper = "!gh auth git-credential";
      gpg.format = "ssh";
      gpg.ssh.program = "${_1passwordSshSignPath}";
      commit.gpgsign = true;
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };
  };

  programs.tmux = {
    enable = true;
    terminal = "tmux";
    aggressiveResize = true;
    secureSocket = true; # If 'false', forces tmux to use /tmp for sockets (WSL2 compat).

    extraConfig = lib.strings.concatStrings (lib.strings.intersperse "\n" ([
      (builtins.readFile ./tmux)
      "run-shell ${sources.tmux-pain-control}/pain_control.tmux"
    ]));
  };

  xresources.extraConfig = builtins.readFile ./Xresources;

  programs.ssh = {
    enable = true;
    extraConfig = ''
    # Personal hosts.
    Host github.com
      User git
      IdentityAgent "${_1passwordAgentPath}"
    Host linode bc
      HostName 172.105.192.143
      IdentityAgent "${_1passwordAgentPath}"
      ForwardAgent yes
    Host skullkid.local
      HostName 192.168.86.43
      IdentityAgent "${_1passwordAgentPath}"
      ForwardAgent yes
    Host 192.168.*
      IdentityAgent "${_1passwordAgentPath}"
    '';
  };

  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = mkIf isLinux {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
