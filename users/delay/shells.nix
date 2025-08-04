{
  lib,
  pkgs,
  ...
}: {
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting message.
        set -g fish_term24bit 1 # Enable true color support.

        fish_vi_key_bindings # Enable vi bindings.

        # Fixes cursor shape behavior in vim mode.
        set fish_cursor_default block
        set fish_cursor_insert block
        set fish_cursor_replace_one block
        set fish_cursor_replace block
        set fish_cursor_external block
        set fish_cursor_visual block
      '';

      functions = {
        fish_mode_prompt = ""; # Disable prompt vi mode reporting.
        fish_prompt = ''
          set_color blue
          printf "\$ "
          set_color normal
        '';
      };
      shellAliases.nixsh = "nix-shell --run ${lib.getExe pkgs.fish}";
    };

    tmux.shell = lib.getExe pkgs.fish;
  };

  home = {
    shell.enableFishIntegration = true;
    sessionVariables.SHELL = lib.getExe pkgs.fish;
    packages = with pkgs; [tmux-open-git-repository-fish];
  };
}
