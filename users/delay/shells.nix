{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (config.modules.usrenv) isHeadless;
  inherit (pkgs.stdenv) isLinux;

  isLinuxDesktop = isLinux && !isHeadless;

  homeDirectory = config.modules.system.users.delay.home;
  codeDirectory = homeDirectory + "/code";
in {
  programs.bash.enable = true;
  programs.bottom.enable = true;
  programs.btop.enable = true;
  programs.htop.enable = true;

  # `cat` replacement.
  programs.bat.enable = true;

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
  };

  programs.direnv = {
    enable = true;
    # enableFishIntegration = true; # read-only; always enabled.
    nix-direnv.enable = true;
    config.whitelist.prefix = [codeDirectory];
  };

  programs.fzf.enable = true;

  programs.skim = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.keychain = {
    enable = true;
    keys = []; # TODO: Add keys.
    enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./config.fish;

    functions.fish_mode_prompt = ""; # Disable prompt vi mode reporting.
    shellAliases = {
      # Shortcut to setup a nix-shell with `fish`. This lets you do something
      # like `nixsh -p go` to get an environment with Go but use `fish` along
      # with it.
      nixsh = "nix-shell --run ${lib.getExe pkgs.fish}";
    };
  };

  programs.zellij.settings.default_shell = lib.getExe pkgs.fish;

  home.sessionVariables.SHELL = lib.getExe pkgs.fish;

  home.packages =
    [
      pkgs.fishPlugins.fzf
      pkgs.fishPlugins.transient-fish
    ]
    ++ lib.optionals isLinuxDesktop [pkgs.nvtopPackages.full];
}
