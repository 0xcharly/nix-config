{
  flake.nixosModules.programs-steam =
    { config, lib, ... }:
    {
      options.node.steam =
        with lib;
        let
          firewallOpts = {
            options = {
              openFirewall = mkEnableOption "Open firewall ports for Steam";
            };
          };
        in
        {
          remotePlay = mkOption {
            type = types.submodule firewallOpts;
            default = { };
            description = ''
              Open ports in the firewall for Steam Remote Play.
            '';
          };
          dedicatedServer = mkOption {
            type = types.submodule firewallOpts;
            default = { };
            description = ''
              Open ports in the firewall for Source Dedicated Server
            '';
          };
          localNetworkGameTransfers = mkOption {
            type = types.submodule firewallOpts;
            default = { };
            description = ''
              Open ports in the firewall for Steam Local Network Game Transfers
            '';
          };
        };

      config.programs.steam = {
        enable = true;

        inherit (config.node.steam) remotePlay dedicatedServer localNetworkGameTransfers;
      };
    };
}
