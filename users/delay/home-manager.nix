{
  inputs,
  isCorpManaged,
  isHeadless,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;

  nvim-pkg = inputs.nvim.packages.${pkgs.system}.stable;
  wezterm-pkg = inputs.wezterm.packages.${pkgs.system}.default;

  _1passwordAgentPathMacOS = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  _1passwordSshSignPathMacOS = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
in {
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  # TODO: try pkgs.tailscale.
  home.packages =
    [
      pkgs.bat
      pkgs.fd
      pkgs.fzf
      pkgs.gh
      pkgs.htop
      pkgs.jq
      pkgs.ripgrep
      pkgs.tree
      pkgs.watch

      pkgs.alejandra
      pkgs.manix
      pkgs.nixd
      pkgs.nixpkgs-fmt

      nvim-pkg

      pkgs.fishPlugins.done
      pkgs.fishPlugins.github-copilot-cli-fish
      pkgs.fishPlugins.fzf
      pkgs.fishPlugins.foreign-env
    ]
    ++ (lib.optionals (!isHeadless) [pkgs.asciinema])
    ++ (lib.optionals isDarwin [pkgs.scrcpy])
    ++ (lib.optionals (isLinux && !isHeadless) [
      # TODO: Reenable when configuration is more stable and reinstall less frequent.
      # Man pages.
      # pkgs.linux-manual
      # pkgs.man-pages
      # pkgs.man-pages-posix

      pkgs.chromium
      # pkgs.firefox
      pkgs.firefox-devedition
      pkgs.rofi
      pkgs.valgrind
      pkgs.zathura # A PDF Viewer.
    ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables =
    {
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      BAT_THEME = "base16";
      PAGER = "less -FirSwX";
      MANPAGER = "${nvim-pkg}/bin/nvim +Man!";
      TERMINAL = "${wezterm-pkg}/bin/wezterm";
    }
    // (lib.optionalAttrs isDarwin {
      HOMEBREW_NO_AUTO_UPDATE = 1;
    });

  xdg = {
    enable = true;
    configFile =
      {
        #   "rofi/config.rasi".text = builtins.readFile ./rofi;
      }
      // (lib.optionalAttrs (isLinux && !isHeadless) {
        #   "ghostty/config".text = builtins.readFile ./ghostty.linux;
      });

    mimeApps = lib.mkIf (isLinux && !isHeadless) {
      defaultApplications = {
        "text/html" = "firefox-devedition.desktop";
        "x-scheme-handler/http" = "firefox-devedition.desktop";
        "x-scheme-handler/https" = "firefox-devedition.desktop";
        "x-scheme-handler/about" = "firefox-devedition.desktop";
        "x-scheme-handler/unknown" = "firefox-devedition.desktop";
      };
    };
  };

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  xsession = lib.mkIf (isLinux && !isHeadless) {
    enable = true;
    windowManager.i3 = rec {
      enable = true;
      config = {
        modifier = "Mod4";
        terminal = "${wezterm-pkg}/bin/wezterm";
        startup = [
          {
            command = config.terminal;
            notification = false;
          }
        ];
        keybindings = {
          "${config.modifier}+Return" = "exec ${config.terminal}";
          "${config.modifier}+o" = "exec ${pkgs.rofi}/bin/rofi -show run";
          "${config.modifier}+1" = "workspace 1";
          "${config.modifier}+2" = "workspace 2";
          "${config.modifier}+3" = "workspace 3";
          "${config.modifier}+4" = "workspace 4";
          "${config.modifier}+5" = "workspace 5";
          "${config.modifier}+Shift+1" = "move container to workspace 1";
          "${config.modifier}+Shift+2" = "move container to workspace 2";
          "${config.modifier}+Shift+3" = "move container to workspace 3";
          "${config.modifier}+Shift+4" = "move container to workspace 4";
          "${config.modifier}+Shift+5" = "move container to workspace 5";
          "${config.modifier}+Shift+c" = "reload";
          "${config.modifier}+Shift+r" = "restart";
        };
        bars = [
          {
            fonts = {
              names = ["IosevkaEtoile" "FontAwesome6Free"];
              style = "Regular";
              size = 12.0;
            };
          }
        ];
      };
    };
  };

  # TODO: Reenable when configuration is more stable and reinstall less frequent.
  # programs.man = {
  #   enable = true;
  #   generateCaches = true;
  # };

  programs.bash.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStringsSep "\n" [
      (builtins.readFile ./config.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
      (lib.optionalString isLinux "eval $(${pkgs.keychain}/bin/keychain --eval --nogui --quiet)")
    ];

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
  };

  programs.wezterm = lib.mkIf (!isHeadless) {
    enable = true;
    package = wezterm-pkg;
    extraConfig = builtins.readFile ./wezterm.lua;
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
    extraConfig =
      {
        branch.autosetuprebase = "always";
        color.ui = true;
        github.user = "0xcharly";
        push.default = "tracking";
        init.defaultBranch = "main";
        branch.sort = "-committerdate";
        credential."https://github.com".helper = "!gh auth git-credential";
        credential."https://gist.github.com".helper = "!gh auth git-credential";
        gpg.format = "ssh";
        commit.gpgsign = true;
        filter.lfs = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
      }
      // (lib.optionalAttrs isDarwin {
        gpg.format = "ssh";
        gpg.ssh.program = _1passwordSshSignPathMacOS;
      });
  };

  programs.tmux = {
    enable = true;
    terminal = "tmux";
    aggressiveResize = true;
    secureSocket = true;

    extraConfig = builtins.readFile ./tmux;
  };

  xresources = lib.mkIf (isLinux && !isHeadless) {
    extraConfig = builtins.readFile ./Xresources;
  };

  programs.ssh = {
    enable = true;
    matchBlocks =
      {
        # Personal hosts.
        "github.com" = {
          user = "git";
          extraOptions =
            lib.optionalAttrs isDarwin {IdentityAgent = "\"${_1passwordAgentPathMacOS}\"";}
            // (lib.optionalAttrs (isLinux && !isHeadless) {IdentityFile = "~/.ssh/github";});
        };
        "linode" = {
          hostname = "172.105.192.143";
          extraOptions =
            lib.optionalAttrs isDarwin {IdentityAgent = "\"${_1passwordAgentPathMacOS}\"";}
            // (lib.optionalAttrs (isLinux && !isHeadless) {IdentityFile = "~/.ssh/linode";});
          forwardAgent = true;
        };
      }
      // (lib.optionalAttrs (isDarwin && !isCorpManaged) {
        # Home storage host.
        "skullkid.local" = {
          hostname = "192.168.86.43";
          extraOptions = {IdentityAgent = "\"${_1passwordAgentPathMacOS}\"";};
          forwardAgent = true;
        };
        # VMWare hosts.
        "192.168.*" = {
          extraOptions = {IdentityAgent = "\"${_1passwordAgentPathMacOS}\"";};
        };
      })
      // (lib.optionalAttrs (isDarwin && isCorpManaged) {
        "*.c.googlers.com" = {
          compression = true;
          remoteForwards = [
            # Forward ADB server port.
            {
              bind.port = 5037;
              host.address = "127.0.0.1";
              host.port = 5037;
            }
          ];
          serverAliveInterval = 60;
          extraOptions = {
            ControlMaster = "auto";
            ControlPath = "~/.ssh/cloudtop-ctrl-%C";
            ControlPersist = "yes";
          };
        };
      });
  };

  # Make cursor not tiny on HiDPI screens.
  home.pointerCursor = lib.mkIf (isLinux && !isHeadless) {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
