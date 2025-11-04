{inputs, ...}: let
  inherit (inputs) deploy-rs nixpkgs;
  inherit (inputs.nixpkgs.lib.attrsets) recursiveUpdate;

  system = "x86_64-linux";

  # Unmodified nixpkgs.
  pkgs = import nixpkgs {inherit system;};
  inherit (pkgs.lib) flatten mapAttrsToList;

  # nixpkgs with deploy-rs overlay but force the nixpkgs package.
  deployPkgs = import nixpkgs {
    inherit system;
    overlays = [
      deploy-rs.overlays.default
      (self: super: {
        deploy-rs = {
          inherit (pkgs) deploy-rs;
          lib = super.deploy-rs.lib;
        };
      })
    ];
  };
in {
  flake = {
    deploy.nodes = let
      hosts = {
        homelabHosts = {
          hostnames = ["heimdall" "bowmore" "skl"];
          options.fastConnection = true;
        };
        frRemoteHosts = {
          hostnames = ["dalmore" "linode-fr"];
          options = {
            fastConnection = false;
            remoteBuild = false; # NOTE: Default when `fastConnection == false`.
          };
        };
        jpRemoteHosts = {
          hostnames = ["linode-jp"];
          options.remoteBuild = false;
        };
      };

      mkDeployHostConfiguration = options: hostname: {
        "${hostname}" = recursiveUpdate options {
          hostname = "${hostname}.neko-danio.ts.net";
          profiles.system.path = deployPkgs.deploy-rs.lib.activate.nixos inputs.self.nixosConfigurations."${hostname}";

          sshUser = "deploy";
          user = "root";
          # TODO: consider either keeping agent forwarding here or moving that
          # to ~/.ssh/config to *.neko-danio.ts.net hosts.
          sshOpts = ["-A" "-i" "/run/agenix/keys/nixos_deploy_ed25519_key"];
        };
      };

      mkDeployConfigurations = group:
        builtins.map (mkDeployHostConfiguration group.options) group.hostnames;

      mkConfigurations = builtins.foldl' recursiveUpdate {};
    in
      mkConfigurations (flatten (mapAttrsToList (_: mkDeployConfigurations) hosts));

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) deploy-rs.lib;
  };
}
