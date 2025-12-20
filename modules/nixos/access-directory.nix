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
        extraGroups = [
          "_files"
          "_media"
          "_music"
          "_pics"
          "_vcs"
          "_zfsadm"
        ];
      };
      ayako.uid = 2001;

      # System users.
      syncoid = {
        uid = 3001;
        isSystemUser = lib.mkDefault true;
        group = lib.mkDefault "syncoid";
        extraGroups = ["_zfsadm"];
      };
      linkwarden = {
        uid = 3002;
        isSystemUser = lib.mkDefault true;
        group = lib.mkDefault "linkwarden";
      };
      git = {
        uid = 3003;
        isNormalUser = true;
        description = "Dedicated user for git tools";
        extraGroups = ["git" "_vcs"];
        group = lib.mkDefault "users";
      };
      cgit = {
        uid = 3004;
        isSystemUser = true;
        extraGroups = ["_vcs"];
        group = lib.mkDefault "cgit";
      };

      # forgejo = {
      #   isSystemUser = lib.mkDefault true;
      #   extraGroups = ["_vcs"];
      #   group = lib.mkDefault "forgejo";
      # };
      # immich = {
      #   isSystemUser = lib.mkDefault true;
      #   extraGroups = ["_pics"];
      #   group = lib.mkDefault "immich";
      # };
      # jellyfin = {
      #   isSystemUser = lib.mkDefault true;
      #   extraGroups = ["_media" "_music"];
      #   group = lib.mkDefault "jellyfin";
      # };
      # navidrome = {
      #   isSystemUser = lib.mkDefault true;
      #   extraGroups = ["_music"];
      #   group = lib.mkDefault "navidrome";
      # };
      # paperless = {
      #   isSystemUser = lib.mkDefault true;
      #   extraGroups = ["_files"];
      #   group = lib.mkDefault "paperless";
      # };
    };

    groups = {
      # Login users' groups.
      # delay.gid = 3000;
      ayako.gid = 2001;

      # System users' groups.
      syncoid.gid = 3001;
      linkwarden.gid = 3002;
      git.gid = 3003;
      cgit.gid = 3004;

      # Standalone groups.
      _zfsadm.gid = 4000;
      _files.gid = 4001;
      _media.gid = 4002;
      _music.gid = 4003;
      _pics.gid = 4004;
      _vcs.gid = 4005;

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
