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
