{ isWSL, inputs, ... }:

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
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  home.stateVersion = "23.11";

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs.asciinema
    pkgs.bat
    pkgs.fd
    pkgs.fzf
    pkgs.gh
    pkgs.htop
    pkgs.jq
    pkgs.ripgrep
    pkgs.tree
    pkgs.watch

    # Node is required for Copilot.vim
    pkgs.nodejs
  ] ++ (lib.optionals isDarwin [
    pkgs.cachix # This is automatically setup on Linux
    pkgs.scrcpy
    # pkgs.tailscale  # TODO: try this out.

  ]) ++ (lib.optionals (isLinux && !isWSL) [
    # pkgs._1password
    # pkgs._1password-gui

    pkgs.chromium
    pkgs.firefox
    pkgs.rofi
    pkgs.valgrind
    pkgs.zathura  # A PDF Viewer.
    pkgs.xfce.xfce4-terminal
  ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
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
      "plugin-title"
    ];
  };

  programs.wezterm = {
    enable = true;
    package = inputs.wezterm.packages.${pkgs.system}.default;
    extraConfig = builtins.readFile ./wezterm.lua;
  };
  home.sessionVariables.TERMINAL = "wezterm";

  programs.i3status = {
    enable = isLinux && !isWSL;

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

  # programs.neovim = {
  #   enable = true;
  #   viAlias = true;
  #   vimAlias = true;
  #   defaultEditor = true;
  #   withPython3 = true;

  #   plugins = with pkgs; [
  #     customVim.vim-fish
  #     customVim.vim-fugitive
  #     customVim.vim-pgsql
  #     customVim.vim-zig
  #     customVim.vim-nix

  #     customVim.nvim-auto-hlsearch
  #     {
  #       plugin = customVim.nvim-catppuccin;
  #       config = ''
  #         packadd! catppuccin
  #         lua << END
  #         vim.o.termguicolors = true
  #         require 'catppuccin'.setup { transparent_background = true }
  #         vim.cmd [[colorscheme catppuccin-mocha]]
  #         END
  #       '';
  #     }

  #     customVim.nvim-comment
  #     customVim.nvim-conform
  #     customVim.nvim-gitsigns
  #     customVim.nvim-lastplace
  #     customVim.nvim-lualine
  #     customVim.nvim-lspconfig
  #     customVim.nvim-neodev
  #     customVim.nvim-nonicons
  #     customVim.nvim-plenary
  #     customVim.nvim-rustacean
  #     customVim.nvim-surround
  #     customVim.nvim-telescope
  #     customVim.nvim-treesitter
  #     customVim.nvim-treesitter-textobjects
  #     customVim.nvim-trouble
  #     customVim.nvim-web-devicons

  #     customVim.vim-markdown
  #   ] ++ (lib.optionals (!isCorpManaged) [
  #     customVim.vim-copilot
  #   ]);

  #   extraConfig = builtins.readFile ./nvim-config.vim;
  #   extraLuaConfig = builtins.readFile ./nvim-config.lua;
  #   #extraConfig = (import ./vim-config.nix) { inherit sources; };
  # };

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    viAlias = true;
    vimAlias = true;

    luaLoader.enable = true;

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparentBackground = true;
        term_colors = true;
      };
    };
    plugins.comment-nvim.enable = true;
    plugins.comment.enable = true;
    plugins.conform-nvim.enable = true;
    plugins.copilot-vim.enable = !isCorpManaged;
    plugins.fugitive.enable = true;
    plugins.gitsigns.enable = true;
    plugins.lastplace.enable = true;
    plugins.nix.enable = true;
    plugins.rustaceanvim.enable = true;
    plugins.surround.enable = true;
    plugins.trouble.enable = true;
    plugins.zig.enable = true;

    # TODO: auto-hlsearch
    # TODO: cmp
    # TODO: fish
    # TODO: lualine
    # TODO: lspconfig
    # TODO: telescope
    # TODO: treesitter
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
    '';
  };

  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = mkIf (isLinux && !isWSL) {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
