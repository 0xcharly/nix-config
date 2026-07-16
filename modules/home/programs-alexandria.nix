# Browses the mail archive on the NAS (Library of Alexandria).
{ self, ... }:
{
  flake.homeModules.programs-alexandria =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "alexandria";
          runtimeInputs = [ pkgs.openssh ];
          text = ''
            exec ssh -t ${self.lib.facts.nas.primary.host} 'exec neomutt'
          '';
        })
      ];
    };
}
