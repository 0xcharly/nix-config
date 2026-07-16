{ self, ... }:
{
  flake.nixosModules.services-qui =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.node.services.qui;
      inherit (self.lib) facts;
    in
    {
      options.node.services.qui = with lib; {
        enable = mkEnableOption "Spin up a qui instance (qBittorrent WebUI)";
      };

      config = lib.mkIf cfg.enable {
        services.qui = {
          enable = true;
          settings = {
            host = "0.0.0.0"; # reverse-proxied from gate-jp over the tailnet
            port = facts.services.qui.port;
          };
          secretFile = "/var/lib/qui-session.secret";
        };

        # services.qui.secretFile is required and read via LoadCredential (by pid1,
        # as root). Locally generated, NOT in nix-config-secrets, deliberately: the
        # session-cookie signing key is consumed by this one process on this one
        # host, has no external counterpart to match (unlike preauth keys/API
        # tokens/host keys), and regenerating it merely logs sessions out — so a
        # repo copy would only widen exposure. The -s guard makes this idempotent;
        # the file persists across reboots so sessions survive restarts.
        systemd.services.qui-session-secret = {
          description = "Generate qui session secret";
          requiredBy = [ "qui.service" ];
          before = [ "qui.service" ];
          serviceConfig.Type = "oneshot";
          script = ''
            if [ ! -s /var/lib/qui-session.secret ]; then
              (umask 077; od -An -N32 -tx1 /dev/urandom | tr -d ' \n' > /var/lib/qui-session.secret)
            fi
          '';
        };
      };
    };
}
