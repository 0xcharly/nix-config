# Common access directory for homelab hosts.
# UIDs:
#   Login users IDs start at 2000
#   System users IDs start at 2100
# GIDs:
#   Login users' group IDs start at 3000
#   System users' group IDs start at 3100
#   Standalone group IDs start at 4000
{flake, inputs, ...}: {
  imports = [
    inputs.nix-config-secrets.modules.nixos.users-delay

    flake.modules.nixos.users-ayako
    flake.modules.nixos.users-delay
  ];

  # TODO: assign common GIDs for these groups.
  users = {
    users = {
      delay = {
        # uid = 2000;
        extraGroups = ["zfsadm"];
      };
      # ayako.uid = 2001;
      syncoid.extraGroups = ["zfsadm"];
    };

    groups = {
      forgejo = {};
      git = {};
      immich = {};
      jellyfin = {};
      navidrome = {};
      paperless = {};
      vaultwarden = {};

      zfsadm.gid = 4000;
    };
  };
}
