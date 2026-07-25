{ self, ... }:
{
  flake.homeModules.programs-atuin = {
    imports = [ self.homeModules.theme-atuin ];

    programs.atuin = {
      enable = true;
      enableFishIntegration = true;
      flags = [ "--disable-up-arrow" ];
    };
  };
}
