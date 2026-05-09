{ self, ... }:
{
  flake.homeModules.programs-file-managers = {
    imports = with self.homeModules; [
      programs-nautilus
      programs-thunar
    ];
  };
}
