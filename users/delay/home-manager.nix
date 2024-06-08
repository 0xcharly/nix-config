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

  open-tmux-workspace-pkg = pkgs.writeShellApplication {
    name = "open-tmux-workspace";
    # Do not add pkgs.mercurial as we need to use the system's version.
    runtimeInputs = [pkgs.tmux];
    text = builtins.readFile ./bin/open-tmux-workspace.sh;
  };

  writePython312 = pkgs.writers.makePythonWriter pkgs.python312 pkgs.python312Packages pkgs.buildPackages.python312Packages;
  writePython312Bin = name: writePython312 "/bin/${name}";

  mdproxyLocalRoot = "~/mdproxy";
in {
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using per-project
  # flakes sourced with direnv and nix-shell, so this is not a huge list.
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
      pkgs.fishPlugins.fzf
      pkgs.fishPlugins.foreign-env

      (pkgs.writeShellScriptBin "term-capabilities" (builtins.readFile ./bin/term-capabilities.sh))
      (pkgs.writeShellScriptBin "term-truecolors" (builtins.readFile ./bin/term-truecolors.sh))

      (pkgs.writeShellApplication {
        name = "generate-gitignore";
        runtimeInputs = [pkgs.curl];
        text = ''curl -sL "https://www.gitignore.io/api/$1"'';
      })

      (writePython312Bin "vault" {
        libraries = with pkgs.python312Packages; [
          bcrypt
          cryptography
        ];
        flakeIgnore = [
          "E501" # Line length.
        ];
      } (builtins.readFile ./bin/vault.py))
    ]
    ++ (
      lib.optionals (isDarwin && isCorpManaged) (
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
              pkgs.writeShellApplication {
                name = "adb-scrcpy-${device.adbId}";
                runtimeInputs = [pkgs.scrcpy];
                text = import ./bin/adb-scrcpy.nix {inherit device;};
              })
            devices)
        )
        ++ (
          let
            # Install missing mdproxy binaries.
            formatters = [
              {
                name = "mdformat";
                path = "/google/bin/releases/corpeng-engdoc/tools/mdformat";
              }
              {
                name = "textpbfmt";
                path = "/google/bin/releases/text-proto-format/public/fmt";
              }
            ];
          in (builtins.map
            (formatter: pkgs.writeShellScriptBin formatter.name ''mdproxy ${formatter.path} "$@"'')
            formatters)
        )
        ++ [
          # Workspace switcher.
          open-tmux-workspace-pkg

          # Config rebuilder.
          (pkgs.writeShellApplication {
            name = "darwin-rebuild-corp";
            runtimeInputs = [inputs.darwin.packages.${pkgs.system}.darwin-rebuild];
            text = builtins.readFile ./bin/darwin-rebuild-corp.sh;
          })
        ]
      )
    )
    ++ lib.optionals isDarwin [
      (pkgs.writeShellApplication {
        name = "adb-scrcpy";
        runtimeInputs = [pkgs.scrcpy];
        text = builtins.readFile ./bin/adb-scrcpy.sh;
      })
    ]
    ++ (lib.optionals (isLinux && !isHeadless) [
      pkgs.firefox-devedition
      pkgs.rofi
      pkgs.valgrind
    ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    BAT_THEME = "base16";
    EDITOR = "${nvim-pkg}/bin/nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "${nvim-pkg}/bin/nvim +Man!";
    TERMINAL = "${pkgs.alacritty}/bin/alacritty";
    # Catppuccin theme for FzF. https://github.com/catppuccin/fzf
    FZF_DEFAULT_OPTS = "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8";
  };

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
          names = ["IosevkaTerm Nerd Font" "FontAwesome6Free"];
          style = "Regular";
          size = 10.0;
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
      (lib.optionalString isCorpManaged ''
        bind \cf ${open-tmux-workspace-pkg}/bin/open-tmux-workspace
        bind -M insert \cf ${open-tmux-workspace-pkg}/bin/open-tmux-workspace
      '')
      (lib.optionalString (isDarwin && isCorpManaged) ''
        set -l MDPROXY_BIN ~/mdproxy/bin
        if test -d "$MDPROXY_BIN"
          fish_add_path "$MDPROXY_BIN"
        end
      '')
    ];

    functions = {
      fish_mode_prompt = ""; # Disable prompt vi mode reporting.
    };
    shellAliases =
      {
        # Shortcut to setup a nix-shell with fish. This lets you do something
        # like `nixsh -p go` to get an environment with Go but use the fish
        # shell along with it.
        nixsh = "nix-shell --run fish";
        devsh = "nix develop --command fish";
        ls = "${pkgs.eza}/bin/eza";
      }
      // (lib.optionalAttrs isLinux {
        # For consistency with macOS.
        pbcopy = "xclip";
        pbpaste = "xclip -o";
      })
      // (lib.optionalAttrs (isLinux && isCorpManaged) {
        bat = "batcat";
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

    extraConfig = lib.strings.concatStringsSep "\n" [
      (builtins.readFile ./tmux.conf)
      (lib.optionalString isCorpManaged ''
        # Citc workspace fuzzy finder.
        bind f run-shell "${pkgs.tmux}/bin/tmux new-window ${open-tmux-workspace-pkg}/bin/open-tmux-workspace"
      '')
    ];
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
