{
  lib,
  pkgs,
  ...
} @ args: let
  inherit (pkgs.stdenv) isLinux;

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
  programs.bash.enable = true;
  programs.htop.enable = true;

  # `cat` replacement.
  programs.bat = {
    enable = true;
    config = {theme = "base16";};
  };

  # `find` replacement.
  programs.fd.enable = true;

  # `grep` replacement.
  programs.ripgrep.enable = true;

  # GitHub command-line integration.
  programs.gh.enable = true;

  # `ls` replacement.
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    # enableFishIntegration = true; # read-only; always enabled.
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config.whitelist.prefix = ["~/code/"];
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

        # See https://zsh.sourceforge.io/Doc/Release/Options.html
        # If you find that you want more control over when commands get
        # imported, you may wish to turn SHARE_HISTORY off, INC_APPEND_HISTORY
        # or INC_APPEND_HISTORY_TIME (see above) on, and then manually import
        # commands whenever you need them using ‘fc -RI’.
        unsetopt SHARE_HISTORY
        setopt INC_APPEND_HISTORY
      ''
      # Our own ZSH plugins.
      ''
        source ${pkgs.open-local-repository-zsh}/share/zsh/plugins/open-local-repository/open-local-repository.plugin.zsh
      ''
      (builtins.readFile ./rprompt.zsh)
      (lib.optionalString isLinux "eval $(${lib.getExe pkgs.keychain} --eval --nogui --quiet)")
    ];
    localVariables = {
      PS1 = "%B%F{blue}_%f%b ";
    };
    shellAliases = shellAliases (lib.getExe pkgs.zsh);
    syntaxHighlighting.enable = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStringsSep "\n" [
      (builtins.readFile ./config.fish)
      (lib.optionalString isLinux "eval (${lib.getExe pkgs.keychain} --eval --nogui --quiet)")
    ];

    functions.fish_mode_prompt = ""; # Disable prompt vi mode reporting.
    shellAliases = shellAliases (lib.getExe pkgs.fish);
  };

  home.packages = [
    pkgs.fishPlugins.done
    pkgs.fishPlugins.fzf
    pkgs.fishPlugins.transient-fish
    pkgs.open-local-repository-fish
  ];
}
