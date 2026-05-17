{ self, inputs, ... }:
{
  flake = {
    nixosConfigurations.fwk-new = inputs.nixpkgs.lib.nixosSystem {
      modules = with self.nixosModules; [
        fwk-host-nixos
        fwk-host-users
      ];
    };

    checks.x86_64-linux.nixos-fwk-new = self.nixosConfigurations.fwk-new.config.system.build.toplevel;
  };
}
