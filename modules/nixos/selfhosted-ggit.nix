# ggit is a home-made read-only web viewer for the GitHub backups on tank.
{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.selfhosted-ggit = moduleWithSystem (
    perSystem@{ config, ... }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.node.services.ggit = with lib; {
        enable = mkEnableOption "Spin up the ggit GitHub-backup viewer";
      };

      config =
        let
          cfg = config.node.services.ggit;
          inherit (self.lib) facts;
        in
        lib.mkIf cfg.enable {
          systemd.services.ggit = {
            description = "ggit - GitHub backup web viewer";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            unitConfig.RequiresMountsFor = [ "/tank/backups/github" ];
            serviceConfig = {
              # Bind 0.0.0.0 so the Caddy reverse-proxy on gate-jp can reach
              # it over the tailnet (same convention as atuin).
              ExecStart = "${lib.getExe perSystem.config.packages.ggit} --listen 0.0.0.0 --port ${toString facts.services.ggit.port} --git ${lib.getExe pkgs.git} /tank/backups/github";
              # Reuse the pre-existing cgit identity (uid/gid 3004); the
              # supplementary `git` group grants read access to the backups.
              User = "cgit";
              Group = "cgit";
              Restart = "on-failure";
              RestartSec = "5s";
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              ReadOnlyPaths = [ "/tank/backups/github" ];
              PrivateDevices = true;
              ProtectKernelTunables = true;
              ProtectControlGroups = true;
              RestrictSUIDSGID = true;
            };
          };
        };
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.ggit = pkgs.callPackage ./_ggit { };
    };
}
