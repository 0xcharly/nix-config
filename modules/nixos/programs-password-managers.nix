{ self, ... }: {
  flake.nixosModules.programs-password-managers.imports = [ self.nixosModules.programs-1password ];
}
