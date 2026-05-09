{ inputs, ... }:
{
  flake.homeModules.atuin = {
    imports = [ inputs.nix-config-colorscheme.homeModules.atuin ];

    programs.atuin = {
      enable = true;
      enableFishIntegration = true;
      flags = [ "--disable-up-arrow" ];
    };
  };
}
