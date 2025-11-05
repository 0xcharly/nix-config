{inputs, ...}: let
  inherit (inputs) deploy-rs nixpkgs;
  inherit (inputs.nixpkgs.lib.attrsets) mergeAttrsList;

  system = "x86_64-linux";

  # Unmodified nixpkgs.
  pkgs = import nixpkgs {inherit system;};

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
      hosts = [
        "bowmore"
        "dalmore"
        "heimdall"
        "linode-fr"
        "linode-jp"
        "skl"
      ];

      mkDeployConfiguration = hostname: {
        "${hostname}" = {
          hostname = "${hostname}.neko-danio.ts.net";
          profiles.system.path = deployPkgs.deploy-rs.lib.activate.nixos inputs.self.nixosConfigurations."${hostname}";

          sshUser = "deploy";
          user = "root";
          # TODO: consider either keeping agent forwarding here or moving that
          # to ~/.ssh/config to *.neko-danio.ts.net hosts.
          sshOpts = ["-A" "-i" "/run/agenix/keys/nixos_deploy_ed25519_key"];
        };
      };
    in
      mergeAttrsList (builtins.map mkDeployConfiguration hosts);

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) deploy-rs.lib;
  };
}
