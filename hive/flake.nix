{
  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    nix-config.url = "path:./..";
  };

  outputs =
    inputs:
    let
      inherit (inputs.nix-config.inputs) nixpkgs;
      inherit (nixpkgs.lib.attrsets) mergeAttrsList;

      system = "x86_64-linux";
      inventory = fromTOML (builtins.readFile ../modules/lib/inventory.toml);

      # Take advantage of the nixpkgs cache instead of building deploy-rs from
      # the flake: Use deploy-rs from nixpkgs to fetch binary from cache with
      # the overlay from inputs.deploy-rs
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          inputs.deploy-rs.overlays.default
          (_: super: {
            deploy-rs = {
              inherit (import nixpkgs { inherit system; }) deploy-rs;
              lib = super.deploy-rs.lib;
            };
          })
        ];
      };

      deploy = {
        nodes =
          let
            mkDeployConfiguration = hostname: {
              "${hostname}" = {
                hostname = "${hostname}.neko-danio.ts.net";
                profiles.system.path =
                  pkgs.deploy-rs.lib.activate.nixos
                    inputs.nix-config.nixosConfigurations."${hostname}";

                sshUser = "root";
                user = "root";
              };
            };
          in
          mergeAttrsList (map mkDeployConfiguration inventory.servers);
      };
    in
    {
      inherit deploy;
      checks = builtins.mapAttrs (_: lib': lib'.deployChecks deploy) inputs.deploy-rs.lib;
    };
}
