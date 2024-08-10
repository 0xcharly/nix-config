{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (config.settings) compositor isCorpManaged;

  hasWindowManager = compositor != "headless";

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
      pbcopy = lib.getExe pkgs.xclip;
      pbpaste = "${lib.getExe pkgs.xclip} -o";
    });
in {
  imports = [
    ./nvim.nix
    ./scripts.nix
    ./x11.nix
    ./wayland.nix
  ];

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
  manual.json.enable = true; # For manix.

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
      pkgs.git-get
      pkgs.htop
      pkgs.lazygit
      pkgs.manix
      pkgs.ripgrep
      pkgs.tree

      pkgs.fishPlugins.done
      pkgs.fishPlugins.fzf
      pkgs.fishPlugins.transient-fish
    ]
    ++ (lib.optionals (isLinux && hasWindowManager) [
      pkgs.firefox-devedition
      pkgs.rofi
      pkgs.valgrind
    ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = let
    nvim-pkg = config.home.nvim-config.finalPackage;
  in {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    BAT_THEME = "base16";
    EDITOR = lib.getExe nvim-pkg;
    PAGER = "less -FirSwX";
    MANPAGER = "${lib.getExe nvim-pkg} +Man!";
    SHELL = lib.getExe pkgs.zsh;
    TERMINAL = lib.getExe pkgs.alacritty;
  };

  xdg = {
    enable = true;
    configFile = {
      # TODO: rofi config.
      # "rofi/config.rasi".text = builtins.readFile ./rofi;
      # TODO: be patient…
      #   "ghostty/config".text = builtins.readFile ./ghostty.linux;
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

  programs.bash.enable = true;

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
      (lib.optionalString isLinux "eval $(${lib.getExe pkgs.keychain} --eval --nogui --quiet)")
    ];
    localVariables = {
      PS1 = "%B%F{grey}:%f%b ";
    };
    shellAliases = shellAliases (lib.getExe pkgs.zsh);
    syntaxHighlighting.enable = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStringsSep "\n" [
      (builtins.readFile ./config.fish)
      "set -g SHELL ${lib.getExe pkgs.fish}"
      (lib.optionalString isLinux "eval (${lib.getExe pkgs.keychain} --eval --nogui --quiet)")
    ];

    functions.fish_mode_prompt = ""; # Disable prompt vi mode reporting.
    shellAliases = shellAliases (lib.getExe pkgs.fish);
  };

  programs.alacritty = lib.mkIf hasWindowManager {
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
        size = 16;
      };
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
      credential."https://github.com".helper = "!gh auth git-credential";
      credential."https://gist.github.com".helper = "!gh auth git-credential";
      gpg =
        {
          format = "ssh";
        }
        // lib.optionalAttrs isDarwin (let
          _1passwordSshSignPathMacOS = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        in {
          ssh.program = _1passwordSshSignPathMacOS;
        });
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

  programs.ssh = let
    _1passwordAgentPathMacOS = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    _1passwordAgentOrKey = key:
      lib.optionalAttrs isDarwin {IdentityAgent = "\"${_1passwordAgentPathMacOS}\"";}
      // lib.optionalAttrs (isLinux && hasWindowManager) {IdentityFile = "~/.ssh/${key}";};
  in {
    enable = true;
    matchBlocks =
      {
        # Personal hosts.
        "github.com" = {
          user = "git";
          extraOptions = _1passwordAgentOrKey "github";
        };
        "linode" = {
          hostname = "172.105.192.143";
          extraOptions = _1passwordAgentOrKey "linode";
          forwardAgent = true;
        };
      }
      // (lib.optionalAttrs (isDarwin && !isCorpManaged) {
        # Home storage host.
        "skullkid.local" = {
          hostname = "192.168.86.43";
          extraOptions = _1passwordAgentOrKey "skullkid";
          forwardAgent = true;
        };
        # VMWare hosts.
        "192.168.*" = {
          extraOptions = _1passwordAgentOrKey "vm";
        };
      });
  };
}
