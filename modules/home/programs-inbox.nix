{ self, ... }:
{
  flake.homeModules.programs-inbox =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "inbox";
          runtimeInputs = [ pkgs.openssh ];
          text = ''
            exec ssh -t ${self.lib.facts.nas.primary.host} 'exec neomutt'
          '';
        })
      ];
    };
}
