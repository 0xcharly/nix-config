{
  inputs,
  lib,
  pkgs,
  isCorpManaged ? false,
  isHeadless ? false,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;

  nvim-pkg =
    if isCorpManaged
    then inputs.nvim.packages.${pkgs.system}.latest-corp
    else inputs.nvim.packages.${pkgs.system}.latest;

  open-tmux-workspace-pkg = pkgs.writeShellApplication {
    name = "open-tmux-workspace";
    # Do not add pkgs.mercurial as we need to use the system's version.
    runtimeInputs = [pkgs.tmux];
    text = builtins.readFile ./bin/open-tmux-workspace.sh;
  };

  writePython312 = pkgs.writers.makePythonWriter pkgs.python312 pkgs.python312Packages pkgs.buildPackages.python312Packages;
  writePython312Bin = name: writePython312 "/bin/${name}";

  mdproxyLocalRoot = "~/mdproxy";
  mdproxy-all-pkgs = let
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
    formatters);

  adb-scrcpy-pkg = pkgs.writeShellApplication {
    name = "adb-scrcpy";
    runtimeInputs = [pkgs.scrcpy];
    text = builtins.readFile ./bin/adb-scrcpy.sh;
  };
  adb-scrcpy-all-specialized-pkgs = (
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
  );
  shellAliases = shell:
    {
      # Shortcut to setup a nix-shell with `shell`. This lets you do something
      # like `nixsh -p go` to get an environment with Go but use `shell` along
      # with it.
      nixsh = "nix-shell --run ${shell}";
      devsh = "nix develop --command ${shell}";
    }
    // (lib.optionalAttrs isLinux {
      # For consistency with macOS.
      pbcopy = "xclip";
      pbpaste = "xclip -o";
    })
    // (lib.optionalAttrs (isLinux && isCorpManaged) {
      bat = "batcat";
    });
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
      pkgs.gh
      pkgs.htop
      pkgs.jq
      pkgs.ripgrep
      pkgs.tree

      # For editing Nix files.
      pkgs.alejandra
      pkgs.nixd

      nvim-pkg

      pkgs.fishPlugins.done
      pkgs.fishPlugins.fzf
      pkgs.fishPlugins.transient-fish

      (pkgs.writeShellScriptBin "term-capabilities" (builtins.readFile ./bin/term-capabilities.sh))
      (pkgs.writeShellScriptBin "term-truecolors" (builtins.readFile ./bin/term-truecolors.sh))

      (pkgs.writeShellApplication {
        name = "generate-gitignore";
        runtimeInputs = [pkgs.curl];
        text = ''curl -sL "https://www.gitignore.io/api/$1"'';
      })

      (writePython312Bin "sekrets" {
        libraries = with pkgs.python312Packages; [
          bcrypt
          cryptography
          rich
        ];
        flakeIgnore = [
          "E501" # Line length.
        ];
      } (builtins.readFile ./bin/sekrets.py))
    ]
    ++ (
      lib.optionals (isDarwin && isCorpManaged) (
        adb-scrcpy-all-specialized-pkgs
        ++ mdproxy-all-pkgs
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
    ++ lib.optionals isDarwin [adb-scrcpy-pkg]
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
    SHELL = "${pkgs.zsh}/bin/zsh";
    TERMINAL = "${pkgs.alacritty}/bin/alacritty";
  };

  xdg = {
    enable = true;
    configFile =
      {
        # TODO: rofi config.
        # "rofi/config.rasi".text = builtins.readFile ./rofi;
      }
      # Raycast expects script attributes to be listed at the top of the file,
      # so a simple wrapper does not work. This *needs* to be a symlink.
      // lib.optionalAttrs isDarwin {
        "raycast/bin/adb-scrcpy".source = "${adb-scrcpy-pkg}/bin/adb-scrcpy";
      }
      // (
        lib.optionalAttrs (isDarwin && isCorpManaged) (
          builtins.listToAttrs (
            builtins.map
            (pkg: {
              name = "raycast/bin/${pkg.name}";
              value = {source = "${pkg}/bin/${pkg.name}";};
            })
            adb-scrcpy-all-specialized-pkgs
          )
        )
      )
      // (lib.optionalAttrs (isLinux && !isHeadless) {
        # TODO: be patient…
        #   "ghostty/config".text = builtins.readFile ./ghostty.linux;
      });
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

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    # Catppuccin theme for FzF. https://github.com/catppuccin/fzf
    colors = {
      bg = "#1e1e2e";
      "bg+" = "#313244";
      fg = "#cdd6f4";
      "fg+" = "#cdd6f4";
      header = "#f38ba8";
      hl = "#f38ba8";
      "hl+" = "#f38ba8";
      info = "#cba6f7";
      marker = "#f5e0dc";
      pointer = "#f5e0dc";
      prompt = "#cba6f7";
      spinner = "#f5e0dc";
    };
  };

  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";
    history = {
      ignoreDups = true;
      ignoreAllDups = true;
    };
    initExtra = lib.strings.concatStringsSep "\n" [
      ''
        setopt HIST_REDUCE_BLANKS
        setopt INC_APPEND_HISTORY # Use `fc -RI` to reload history.
      ''
      (builtins.readFile ./rprompt.zsh)
      (lib.optionalString isLinux "eval $(${pkgs.keychain}/bin/keychain --eval --nogui --quiet)")
      (lib.optionalString isCorpManaged (builtins.readFile ./tmux-open-citc-workspace.zsh))
      (lib.optionalString (isDarwin && isCorpManaged) (let
        mdproxy_zshrc = "${mdproxyLocalRoot}/data/mdproxy_zshrc";
      in ''
        [[ -e "${mdproxy_zshrc}" ]] && source "${mdproxy_zshrc}" # MDPROXY-ZSHRC
      ''))
    ];
    localVariables = {
      PS1 = "%B%F{grey}:%f%b ";
    };
    shellAliases = shellAliases "${pkgs.zsh}/bin/zsh";
    syntaxHighlighting.enable = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStringsSep "\n" [
      (builtins.readFile ./config.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
      (lib.optionalString isLinux "eval (${pkgs.keychain}/bin/keychain --eval --nogui --quiet)")
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

    functions.fish_mode_prompt = ""; # Disable prompt vi mode reporting.
    shellAliases = shellAliases "${pkgs.fish}/bin/fish";
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
            lib.optionalAttrs (!isHeadless) {IdentityFile = "~/.ssh/vm";};
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
