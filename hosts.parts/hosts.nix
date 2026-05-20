{ self, inputs, ... }:
{
  flake = {
    nixosConfigurations = {
      cloud9 = inputs.nixpkgs.lib.nixosSystem {
        modules = with self.nixosModules; [
          cloud9-host-nixos
          cloud9-host-users
        ];
      };

      fwk-new = inputs.nixpkgs.lib.nixosSystem {
        modules = with self.nixosModules; [
          fwk-host-nixos
          fwk-host-users
        ];
      };

      skl = inputs.nixpkgs.lib.nixosSystem {
        modules = with self.nixosModules; [
          skl-host-nixos
          skl-host-users
        ];
      };
    };

    checks.x86_64-linux = {
      nixos-cloud9 = self.nixosConfigurations.cloud9.config.system.build.toplevel;
      nixos-fwk-new = self.nixosConfigurations.fwk-new.config.system.build.toplevel;
      nixos-skl = self.nixosConfigurations.skl.config.system.build.toplevel;
    };
  };
}
