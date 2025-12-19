# Common access directory for homelab hosts.
# UIDs:
#   Login users IDs start at 2000
#   System users IDs start at 3000
# GIDs:
#   Login users' group IDs start at 2000
#   System users' group IDs start at 3000
#   Standalone group IDs start at 4000
{
  flake,
  inputs,
  ...
}: {lib, ...}: {
  imports = [
    inputs.nix-config-secrets.modules.nixos.users-delay

    flake.modules.nixos.users-ayako
    flake.modules.nixos.users-delay
  ];

  # TODO: assign common GIDs for these groups.
  users = {
    users = {
      # Login users.
      delay = {
        # uid = 2000;
        extraGroups = ["zfsadm"];
      };
      ayako.uid = 2001;

      # System users.
      syncoid = {
        uid = 3001;
        isSystemUser = lib.mkDefault true;
        group = lib.mkDefault "syncoid";
        extraGroups = ["zfsadm"];
      };
      linkwarden = {
        uid = 3002;
        isSystemUser = lib.mkDefault true;
        group = lib.mkDefault "linkwarden";
      };
    };

    groups = {
      # Login users' groups.
      # delay.gid = 3000;
      ayako.gid = 2001;

      # System users' groups.
      syncoid.gid = 3001;
      linkwarden.gid = 3002;

      # Standalone groups.
      zfsadm.gid = 4000;

      # TODO: Migrate the remaining groups.
      forgejo = {};
      git = {};
      immich = {};
      jellyfin = {};
      navidrome = {};
      paperless = {};
      vaultwarden = {};
    };
  };
}
