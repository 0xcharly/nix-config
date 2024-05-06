{ currentSystemName
, inputs
, isCorpManaged
, ...
}: { lib
   , pkgs
   , ...
   }:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isDarwin isLinux;

  _1passwordAgentPath = (
    if isDarwin
    then "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else "~/.1password/agent.sock"
  );
  _1passwordSshSignPath = (
    if isDarwin
    then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else "${pkgs._1password-gui}/bin/op-ssh-sign"
  );
in
{
  # imports = [ (import ./nvim { inherit inputs isCorpManaged; }) ];

  home.stateVersion = "23.11";

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = with pkgs;
    [
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

      inputs.nvim.packages.${pkgs.system}.stable

      nixd
      nixpkgs-fmt
    ]
    ++ (lib.optionals isDarwin [
      scrcpy
      # tailscale  # TODO: try this out.
    ])
    ++ (lib.optionals isLinux [
      # TODO: Reenable when configuration is more stable and reinstall less frequent.
      # Man pages.
      # linux-manual
      # man-pages
      # man-pages-posix

      chromium
      # firefox
      firefox-devedition
      rofi
      valgrind
      zathura # A PDF Viewer.
    ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables =
    {
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      PAGER = "less -FirSwX";
      MANPAGER = "nvim +Man!";
      BAT_THEME = "base16";
      TERMINAL = "wezterm";
    }
    // (lib.optionalAttrs isDarwin {
      HOMEBREW_NO_AUTO_UPDATE = 1;
    });

  xdg.enable = true;
  xdg.configFile =
    {
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
    }
    // (lib.optionalAttrs isDarwin {
      #   # Rectangle.app. This has to be imported manually using the app.
      #   "rectangle/RectangleConfig.json".text = builtins.readFile ./RectangleConfig.json;
    })
    // (lib.optionalAttrs isLinux {
      #   "ghostty/config".text = builtins.readFile ./ghostty.linux;
      #   "i3/config".text = builtins.readFile ./i3;
    });

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
          {
            command = "xrandr-auto";
            notification = false;
          }
        ];
        keybindings = import ./i3-keybindings.nix config.modifier;
      };
      #extraConfig = builtins.readFile ./i3;
    };
  };

  programs.home-manager.enable = true;

  # TODO: Reenable when configuration is more stable and reinstall less frequent.
  # programs.man = {
  #   enable = true;
  #   generateCaches = true;
  # };

  programs.bash.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStrings (lib.strings.intersperse "\n" [
      (builtins.readFile ./config.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
    ]);

    shellAliases =
      {
        # Shortcut to setup a nix-shell with fish. This lets you do something like
        # `nixsh -p go` to get an environment with Go but use the fish shell along
        # with it.
        nixsh = "nix-shell --run fish";
        devsh = "nix develop --command fish";
        ls = "${pkgs.eza}/bin/eza";
      }
      // (lib.optionalAttrs isLinux {
        # For consistency with macOS.
        pbcopy = "xclip";
        pbpaste = "xclip -o";
      });

    plugins =
      map
        (n: {
          name = n;
          src = pkgs.fishPlugins.${n};
        }) [
        "fzf"
        "foreign-env"
      ];
  };

  programs.wezterm = {
    enable = true;
    package = inputs.wezterm.packages.${pkgs.system}.default;
    extraConfig = lib.strings.concatStrings (lib.strings.intersperse "\n" [
      (builtins.readFile ./wezterm.lua)
      (lib.optionalString isDarwin
        ''
          config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
          config.window_padding = { top = 48, left = 0, right = 0, bottom = 0 }
        '')
      (lib.optionalString isLinux
        ''
          config.window_decorations = 'NONE'
          config.window_padding = { top = 8, left = 0, right = 0, bottom = 0 }
        '')
      ''
        return config
      ''
    ]);
  };

  programs.i3status = mkIf isLinux {
    enable = true;

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

    extraConfig = builtins.readFile ./tmux;
  };

  xresources.extraConfig = builtins.readFile ./Xresources;

  programs.ssh = {
    enable = true;
    extraConfig =
      ''
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
      ''
      + lib.optionalString (currentSystemName == "darwin") ''
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
