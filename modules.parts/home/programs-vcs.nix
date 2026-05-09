{ self, ... }:
{
  flake.homeModules.programs-vcs = {
    imports = with self.homeModules; [
      programs-git
      programs-jujutsu
    ];
  };
}
