{ self, ... }:
{
  flake.homeModules.programs-atuin = {
    imports = [ self.homeModules.colors-atuin ];

    programs.atuin = {
      enable = true;
      enableFishIntegration = true;
      flags = [ "--disable-up-arrow" ];
    };
  };
}
