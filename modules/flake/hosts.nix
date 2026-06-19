{
  config,
  inputs,
  lib,
  ...
}:
with lib;
{
  options.my.hosts = mkOption {
    type = types.lazyAttrsOf (
      types.submodule {
        options = {
          stateVersion = mkOption {
            type = types.singleLineStr;
            description = ''
              The first version of NixOS / Home-Manager installed on this
              particular machine, used to maintain compatibility with app
              data (e.g. databases) created on older NixOS versions.

              https://search.nixos.org/options?query=system.stateVersion
            '';
          };

          nixosModule = mkOption {
            type = types.deferredModule;
            visible = "shallow";
          };

          users = mkOption {
            type = types.attrsOf types.deferredModule;
            visible = "shallow";
          };
        };
      }
    );
  };

  config.flake = {
    nixosConfigurations = flip mapAttrs config.my.hosts (
      hostName:
      {
        stateVersion,
        nixosModule,
        users,
        ...
      }:
      inputs.nixpkgs.lib.nixosSystem {
        modules = [
          nixosModule # NixOS module

          # Common modules
          (
            { modulesPath, ... }:
            {
              imports = [
                "${modulesPath}/installer/scan/not-detected.nix"
              ];
            }
          )

          # System module
          {
            networking = {
              inherit hostName;
              domain = "qyrnl.com";
            };

            nixpkgs.hostPlatform = "x86_64-linux";
            system = { inherit stateVersion; };
          }

          # Home Manager module
          {
            imports = [ inputs.home-manager.nixosModules.default ];

            home-manager = {
              # Injects home.stateVersion into the Home Manager module
              users = flip mapAttrs users (
                _: userModule:
                mkMerge [
                  userModule
                  { home = { inherit stateVersion; }; }
                ]
              );
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
        ];
      }
    );

    checks =
      with lib;
      config.flake.nixosConfigurations
      |> mapAttrsToList (
        name: nixos: {
          ${nixos.config.nixpkgs.hostPlatform.system} = {
            "configurations:nixos:${name}" = nixos.config.system.build.toplevel;
          };
        }
      )
      |> mkMerge;
  };
}
