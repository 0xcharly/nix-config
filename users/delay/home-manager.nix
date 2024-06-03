{
  inputs,
  isCorpManaged,
  isHeadless,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;

  nvim-pkg = inputs.nvim.packages.${pkgs.system}.latest;

  mdproxyLocalRoot = "~/mdproxy";
in {
  home.stateVersion = "24.05";
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

      pkgs.tldr

      nvim-pkg

      pkgs.fishPlugins.done
      pkgs.fishPlugins.fzf
      pkgs.fishPlugins.foreign-env

      (pkgs.writeShellScriptBin "term-capabilities" (builtins.readFile ./bin/term-capabilities.sh))
      (pkgs.writeShellScriptBin "term-truecolors" (builtins.readFile ./bin/term-truecolors.sh))
    ]
    ++ (
      lib.optionals (isDarwin && isCorpManaged)
      (
        let
          devices = [
            {
              adbId = "33301JEHN18611";
              name = "Pixel 7a";
            }
            {
              adbId = "35061FDHS000A4";
              name = "Pixel Fold";
            }
            {
              adbId = "98311FFAZ004TE";
              name = "Pixel 4";
            }
            {
              adbId = "99091FFBA005TS";
              name = "Pixel 4 XL";
            }
          ];
        in (builtins.map
          (device:
            pkgs.writeShellScriptBin "adb-scrcpy-${device.adbId}"
            (import ./bin/adb-scrcpy.nix {inherit device;}))
          devices)
      )
      ++ [
        (pkgs.writeShellScriptBin "adb-scrcpy" (builtins.readFile ./bin/adb-scrcpy.sh))
        (pkgs.writeShellScriptBin "darwin-rebuild-corp" (builtins.readFile ./bin/darwin-rebuild-corp.sh))
        (pkgs.writeShellScriptBin "open-tmux-workspace" (builtins.readFile ./bin/open-tmux-workspace.sh))
      ]
    )
    ++ (lib.optionals (!isCorpManaged) [pkgs.fishPlugins.github-copilot-cli-fish])
    ++ (lib.optionals (!isHeadless) [pkgs.asciinema])
    ++ (lib.optionals isDarwin [pkgs.scrcpy])
    ++ (lib.optionals (isLinux && !isHeadless) [
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
      EDITOR = "${nvim-pkg}/bin/nvim";
      PAGER = "less -FirSwX";
      MANPAGER = "${nvim-pkg}/bin/nvim +Man!";
      TERMINAL = "${pkgs.alacritty}/bin/alacritty";
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

  xsession = lib.mkIf (isLinux && !isHeadless) {
    enable = true;
    windowManager.i3 = rec {
      enable = true;
      config = let
        fonts = {
          names = ["MonaspaceKrypton" "FontAwesome6Free"];
          style = "Regular";
          size = 12.0;
        };
      in {
        modifier = "Mod4";
        terminal = "${pkgs.alacritty}/bin/alacritty";
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
          "${config.modifier}+Left" = "focus left";
          "${config.modifier}+Right" = "focus right";
          "${config.modifier}+Up" = "focus up";
          "${config.modifier}+Down" = "focus down";
          "${config.modifier}+Shift+Left" = "move left";
          "${config.modifier}+Shift+Right" = "move right";
          "${config.modifier}+Shift+Up" = "move up";
          "${config.modifier}+Shift+Down" = "move down";
          "${config.modifier}+Shift+1" = "move container to workspace 1";
          "${config.modifier}+Shift+2" = "move container to workspace 2";
          "${config.modifier}+Shift+3" = "move container to workspace 3";
          "${config.modifier}+Shift+4" = "move container to workspace 4";
          "${config.modifier}+Shift+5" = "move container to workspace 5";
          "${config.modifier}+Shift+c" = "reload";
          "${config.modifier}+Shift+r" = "restart";
        };
        inherit fonts;
        bars = [{inherit fonts;}];
      };
    };
  };

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    # enableFishIntegration = true; # read-only; always enabled.
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config.whitelist.prefix = ["~/code/"];
  };

  programs.bash.enable = true;

  home.file.".bash_profile".source = lib.mkForce (pkgs.writeTextFile {
    name = "bash_profile";
    text =
      ''
        # include .profile if it exists
        [[ -f ~/.profile ]] && . ~/.profile

        # include .bashrc if it exists
        [[ -f ~/.bashrc ]] && . ~/.bashrc
      ''
      + lib.optionalString (isDarwin && isCorpManaged) (
        let
          mdproxy_bash_profile = "${mdproxyLocalRoot}/data/mdproxy_bash_profile";
        in ''
          [[ -z "$ZSH_VERSION" && -e "${mdproxy_bash_profile}" ]] && source "${mdproxy_bash_profile}" # MDPROXY-BASH-PROFILE
        ''
      );
    checkPhase = ''
      ${pkgs.stdenv.shellDryRun} "$target"
    '';
  });

  programs.zsh = {
    enable = true;
    initExtra = lib.optionalString (isDarwin && isCorpManaged) (let
      mdproxy_zshrc = "${mdproxyLocalRoot}/data/mdproxy_zshrc";
    in ''
      [[ -e "${mdproxy_zshrc}" ]] && source "${mdproxy_zshrc}" # MDPROXY-ZSHRC
    '');
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStringsSep "\n" [
      (builtins.readFile ./config.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
      (lib.optionalString isLinux "eval $(${pkgs.keychain}/bin/keychain --eval --nogui --quiet)")
      (lib.optionalString (isDarwin && isCorpManaged) ''
        set -l MDPROXY_BIN ~/mdproxy/bin
        if test -d "$MDPROXY_BIN"
          fish_add_path "$MDPROXY_BIN"
        end
      '')
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

  programs.alacritty = lib.mkIf (!isHeadless) {
    enable = true;
    settings = {
      import = [pkgs.alacritty-theme.catppuccin_mocha];
      env.TERM = "alacritty";
      font = {
        normal = {
          family = "IosevkaTerm Nerd Font";
          style = "Light";
        };
        bold = {
          family = "IosevkaTerm Nerd Font";
          style = "Medium";
        };
        size = 14;
      };
      hints.enabled = lib.optionals isCorpManaged (
        let
          open-cmd =
            if isDarwin
            then "open"
            else "xdg-open";
          open-g3-short-links = pkgs.writeShellScriptBin "open-g3-short-links" ''
            ${open-cmd} "http://$1"
          '';
          g3-hyperlink = regex: {
            inherit regex;
            hyperlinks = true;
            post_processing = true;
            mouse.enabled = true;
            command = "${open-g3-short-links}/bin/open-g3-short-links";
          };
        in [
          (g3-hyperlink "b/[0-9]+")
          (g3-hyperlink "cl/[0-9]+")
          {
            regex = "http://sponge2/[0-9a-z-]+";
            hyperlinks = true;
            post_processing = true;
            mouse.enabled = true;
            command = open-cmd;
          }
        ]
      );
      keyboard.bindings = lib.optionals isDarwin [
        {
          key = "Tab";
          mods = "Control";
          action = "SelectNextTab";
        }
        {
          key = "Tab";
          mods = "Control|Shift";
          action = "SelectPreviousTab";
        }
      ];
      window = {
        decorations = "Full";
        padding = {
          x = 4;
          y = 4;
        };
      };
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
    secureSocket = true;

    clock24 = true;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    sensibleOnTop = false;

    extraConfig = builtins.readFile ./tmux.conf;
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
          extraOptions = lib.optionalAttrs (!isHeadless) {IdentityFile = "~/.ssh/github";};
        };
        "linode" = {
          hostname = "172.105.192.143";
          extraOptions = lib.optionalAttrs (!isHeadless) {IdentityFile = "~/.ssh/linode";};
          forwardAgent = true;
        };
      }
      // (lib.optionalAttrs (isDarwin && !isCorpManaged) {
        # Home storage host.
        "skullkid.local" = {
          hostname = "192.168.86.43";
          extraOptions =
            lib.optionalAttrs (!isHeadless) {IdentityFile = "~/.ssh/skullkid";};
          forwardAgent = true;
        };
        # VMWare hosts.
        "192.168.*" = {
          extraOptions =
            lib.optionalAttrs (!isHeadless) {IdentityFile = "~/.ssh/vm-aarch64";};
        };
      })
      // (lib.optionalAttrs (isDarwin && isCorpManaged) {
        "*.c.googlers.com" = {
          compression = true;
          forwardAgent = true;
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
            ControlPath = "~/.ssh/master-%C";
            ControlPersist = "yes";
          };
        };
      });
    includes = lib.optionals (isDarwin && isCorpManaged) ["~/mdproxy/data/ssh_config"];
  };

  # Make cursor not tiny on HiDPI screens.
  home.pointerCursor = lib.mkIf (isLinux && !isHeadless) {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
