{ self, ... }:
{
  my.hosts.iso = {
    stateVersion = "25.11";
    nixosModule = {
      imports = [ self.nixosModules.iso-provisioning ];

      # TODO(26.11): Set to `false` to silence build warning. Remove once fix is
      # submitted upstream.
      boot.zfs.forceImportRoot = false;
    };
  };
}
