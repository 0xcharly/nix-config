# Read-only HTTP server for the public file share on tank.
#
# Serves /tank/delay/files/public over the tailnet; the public reverse proxy
# on gate-jp exposes it to the internet at https://xn--7ck8cva5eb.com/public.
# static-web-server only implements GET/HEAD (plus OPTIONS) and confines
# lookups to its root — `../` escapes are rejected by both sws and the
# path-normalizing Caddy proxy in front of it.
{ self, ... }:
{
  flake.nixosModules.selfhosted-public-files =
    { config, lib, ... }:
    {
      options.node.services.public-files = with lib; {
        enable = mkEnableOption "Serve the public file share from tank";
      };

      config =
        let
          cfg = config.node.services.public-files;
          inherit (self.lib) facts;
        in
        lib.mkIf cfg.enable {
          services.static-web-server = {
            enable = true;
            # Bind all interfaces so the Caddy reverse-proxy on gate-jp can
            # reach it over the tailnet (same convention as atuin).
            listen = "[::]:${toString facts.services.public-files.port}";
            root = "/tank/delay/files/public";
            # Listing is deliberate: the whole tree is public by design.
            configuration.general.directory-listing = true;
          };

          systemd.services.static-web-server = {
            # Never serve an unmounted /tank (would expose the empty stub
            # directory on the root dataset).
            after = [ "zfs-mount-tank.service" ];
            requires = [ "zfs-mount-tank.service" ];
            unitConfig.ConditionPathIsMountPoint = "/tank/delay/files";
            # The unit runs with DynamicUser; the supplementary `www-data`
            # group (declared in access-directory.nix) grants read access to
            # the share (0750 delay:www-data, reached through the
            # world-traversable /tank/delay/files — see fs-zfs-mount-tank.nix).
            # mkForce keeps the NixOS module's leading "" (which resets the
            # upstream unit's hardcoded `www-data` group) ahead of ours.
            serviceConfig.SupplementaryGroups = lib.mkForce [
              ""
              "www-data"
            ];
          };
        };
    };
}
