# Central storage for the Blocky DNS query log.
#
# The gates' Blocky instances (selfhosted-dns-qyrnl-dot-com) batch-write
# their query logs to this PostgreSQL database over the tailnet; Grafana on
# the same host reads it back for the "Top queried domains" / "Top blocked
# domains" panels on the Blocky dashboard.
{ self, ... }:
{
  flake.nixosModules.selfhosted-blocky-query-log =
    { config, lib, ... }:
    {
      options.node.services.blocky-query-log = with lib; {
        enable = mkEnableOption "Host the PostgreSQL database backing the Blocky query log";
      };

      config =
        let
          cfg = config.node.services.blocky-query-log;
          inherit (self.lib) facts;
          inherit (facts.services.blocky.query-log) database user;
        in
        lib.mkIf cfg.enable {
          services.postgresql = {
            enable = true;
            # Wildcard bind: reachable over the tailnet via tailscaled's
            # ts-input chain for the gates' Blocky instances; the default-deny
            # firewall keeps it closed on eth0 (do NOT open it).
            enableTCPIP = true;
            ensureDatabases = [ database ];
            ensureUsers = [
              {
                name = user;
                # Owner rights let blocky's gorm auto-migration create the
                # log_entries table on first connect.
                ensureDBOwnership = true;
              }
            ];
            # Trust scoped to the query-log database/user instead of a
            # password: blocky's config is a nix-store YAML, so a password
            # would leak into the world-readable store. The tailnet is
            # WireGuard-authenticated, and Grafana already serves the same
            # data anonymously, so this grants nothing new. These entries
            # land before the NixOS defaults (which are mkAfter'd), taking
            # precedence over `host all all 127.0.0.1/32 md5`.
            authentication = ''
              # Gates' Blocky instances, over the tailnet.
              host ${database} ${user} ${facts.dns."qyrnl.com".ns1.ipv4}/32 trust
              host ${database} ${user} ${facts.dns."qyrnl.com".ns2.ipv4}/32 trust
              # Grafana's query-log datasource, on this host (loopback TCP:
              # peer auth does not apply to the grafana OS user).
              host ${database} ${user} 127.0.0.1/32 trust
            '';
          };
        };
    };
}
