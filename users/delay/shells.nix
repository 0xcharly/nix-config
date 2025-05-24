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
    eza.enableFishIntegration = true;
    keychain.enableFishIntegration = true;
    # programs.direnv.enableFishIntegration = true; # read-only; always enabled.
  };

  home = {
    sessionVariables.SHELL = lib.getExe pkgs.fish;
    packages = [
      pkgs.fishPlugins.fzf
      pkgs.fishPlugins.transient-fish
    ];
  };
}
