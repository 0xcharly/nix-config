{
  config,
  pkgs,
  pkgs',
  ...
}:
{
  home.packages = [
    pkgs'.devenv # For managing development environments.
    pkgs.git-get # Used along with fzf and terminal multiplexers for repository management.
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      warn_timeout = 0;
      whitelist.prefix = [ "${config.home.homeDirectory}/code" ];
    };
  };
}
