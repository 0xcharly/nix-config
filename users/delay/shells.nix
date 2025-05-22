{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
in {
  programs.bash.enable = true;
  programs.bottom.enable = true;
  programs.btop.enable = true;
  programs.htop.enable = true;
  programs.bat.enable = true; # `cat` replacement.
  programs.fd.enable = true; # `find` replacement.
  programs.ripgrep.enable = true; # `grep` replacement.
  programs.gh.enable = true; # GitHub command-line integration.
  programs.eza.enable = true; # `ls` replacement.
  programs.fzf.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.whitelist.prefix = [
      "${config.home.homeDirectory}/code"
    ];
  };

  programs.keychain = {
    enable = lib.mkDefault true;
    keys = []; # TODO: Add keys.
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./fish/config.fish;

    functions.fish_mode_prompt = ""; # Disable prompt vi mode reporting.
    # Shortcut to setup a nix-shell with `fish`. This lets you do something
    # like `nixsh -p go` to get an environment with Go but use `fish` along
    # with it.
    shellAliases.nixsh = "nix-shell --run ${lib.getExe pkgs.fish}";
  };
  programs.eza.enableFishIntegration = true;
  programs.keychain.enableFishIntegration = true;
  # programs.direnv.enableFishIntegration = true; # read-only; always enabled.

  home.sessionVariables.SHELL = lib.getExe pkgs.fish;

  home.packages = [
    pkgs.fishPlugins.fzf
    pkgs.fishPlugins.transient-fish
  ];
}
