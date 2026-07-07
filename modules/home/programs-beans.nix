{ self, ... }:
{
  flake.homeModules.programs-beans =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "beans";
          runtimeInputs = [ pkgs.openssh ];
          text = ''
            exec ssh -t ${self.lib.facts.nas.primary.host} \
              'cd /tank/delay/beans && exec nix develop --command nvim delay.beancount'
          '';
        })
      ];
    };
}
