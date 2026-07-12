{
  flake.nixosModules.services-tailscale =
    { config, lib, ... }:
    let
      cfg = config.node.networking.tailscale;
    in
    {
      options.node.networking.tailscale = with lib; {
        enableSsh = mkEnableOption "Whether to enable Tailscale SSH";
        acceptRoutes = mkEnableOption "Whether to accept routes advertised by other peers";
        operator = {
          enable = mkEnableOption "Whether to let a local user operate tailscaled without sudo";
          user = mkOption {
            type = types.str;
            default = "delay";
            description = "The local user allowed to operate tailscaled (tailscale set ...) without sudo.";
          };
        };
        exitNode = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Tailscale exit node (IP, base name, or auto:any) for internet
            traffic, or empty string to not use an exit node
          '';
        };
        exitNodeAllowLanAccess =
          mkEnableOption ''
            Allow direct access to the local network when routing traffic via an exit node.

            Defaults to true if --exit-node= is set.
          ''
          // {
            default = cfg.exitNode != null;
          };
      };

      config = {
        # Create group Tailscale
        users.groups.tailscale = { };

        services.tailscale = {
          enable = true;
          authKeyFile = config.age.secrets."services/tailscale-preauth.key".path;
          extraSetFlags =
            with lib;
            let
              booleanFlag = flip optional;
              stringFlag = flag: value: optional (value != null) "${flag}=${value}";
              mkFlags = f: flags: f |> flip mapAttrsToList flags |> concatLists;
            in
            concatLists [
              (mkFlags booleanFlag {
                "--ssh" = cfg.enableSsh;
                "--accept-routes" = cfg.acceptRoutes;
                "--exit-node-allow-lan-access" = cfg.exitNodeAllowLanAccess;
              })
              (mkFlags stringFlag {
                "--exit-node" = cfg.exitNode;
                "--operator" = if cfg.operator.enable then cfg.operator.user else null;
              })
            ];
        };

        assertions = [
          {
            assertion = cfg.exitNodeAllowLanAccess -> cfg.exitNode != null;
            message = "--exit-node-allow-lan-access=true requires --exit-node=";
          }
        ];
      };
    };
}
