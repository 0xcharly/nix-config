{ self, ... }:
{
  my.hosts.iso = {
    stateVersion = "25.11";
    nixosModule.imports = [ self.nixosModules.iso-provisioning ];
  };
}
