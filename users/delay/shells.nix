{
  lib,
  pkgs,
  ...
}: {
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = builtins.readFile ./fish/config.fish;

      functions.fish_mode_prompt = ""; # Disable prompt vi mode reporting.
      # Shortcut to setup a nix-shell with `fish`. This lets you do something
      # like `nixsh -p go` to get an environment with Go but use `fish` along
      # with it.
      shellAliases.nixsh = "nix-shell --run ${lib.getExe pkgs.fish}";
    };
    # TODO: consider using home.shell.enableFishIntegration instead.
    eza.enableFishIntegration = true;
    keychain.enableFishIntegration = true;
    # direnv.enableFishIntegration = true; # read-only; always enabled.
    tmux.shell = lib.getExe pkgs.fish;

    nushell = {
      enable = true;
      environmentVariables = {
        PROMPT_COMMAND = lib.hm.nushell.mkNushellInline ''{ || $"(ansi blue_bold)▶_(ansi reset) " }'';
        PROMPT_COMMAND_RIGHT = "";
        PROMPT_INDICATOR_VI_INSERT = "";
        PROMPT_INDICATOR_VI_NORMAL = "";
        TRANSIENT_PROMPT_COMMAND = lib.hm.nushell.mkNushellInline ''{ || $"(ansi dark_gray_bold)>:(ansi reset) " }'';
      };
      settings = {
        buffer_editor = lib.getExe pkgs.nvim;
        edit_mode = "vi";
        show_banner = false;
      };
    };
  };

  home = {
    shell.enableNushellIntegration = true;
    sessionVariables.SHELL = lib.getExe pkgs.fish;
    packages = with pkgs; [
      fishPlugins.fzf
      fishPlugins.transient-fish

      tmux-open-git-repository-fish
    ];
  };
}
