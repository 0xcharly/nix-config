{ self, ... }:
{
  flake.homeModules.programs-ssh = {
    imports = with self.homeModules; [
      programs-ssh-config
      programs-ssh-config-forgejo
    ];
  };
}
